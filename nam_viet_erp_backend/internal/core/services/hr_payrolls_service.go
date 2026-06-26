package services

import (
	"context"

	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/repository/postgres"
	"gorm.io/gorm"
)

type HRPayrollsService interface {
	CalculatePayroll(ctx context.Context, tx *gorm.DB, userID string, req domain.PayrollCalculateRequest) (*domain.HRPayroll, error)
}

type hrPayrollsService struct {
	repo postgres.HRPayrollsRepository
}

func NewHRPayrollsService(repo postgres.HRPayrollsRepository) HRPayrollsService {
	return &hrPayrollsService{repo: repo}
}

func (s *hrPayrollsService) CalculatePayroll(ctx context.Context, tx *gorm.DB, userID string, req domain.PayrollCalculateRequest) (*domain.HRPayroll, error) {
	contract, err := s.repo.GetActiveContract(ctx, tx, userID)
	if err != nil {
		// return default if no active contract found
		return nil, err
	}

	commission := 0.0
	kpiBonus := 0.0

	// General KPI Engine (Actual Data Fetcher & Reward Matching)
	var targets []domain.HRKPITarget
	if err := tx.WithContext(ctx).Where("employee_id = ? AND month = ? AND year = ?", userID, req.Month, req.Year).Find(&targets).Error; err == nil {
		
		var rewardRules []domain.HRKPIRewardRule
		if err := tx.WithContext(ctx).Find(&rewardRules).Error; err == nil {
			
			for _, target := range targets {
				actualValue := 0.0
				
				// A. Actual Data Fetcher
				switch target.MetricCode {
				case "SALES_REVENUE":
					// Extract month logic for postgres: EXTRACT(MONTH FROM created_at)
					tx.WithContext(ctx).Table("orders").
						Select("COALESCE(SUM(final_amount), 0)").
						Where("creator_id = ? AND status = 'completed' AND EXTRACT(MONTH FROM created_at) = ? AND EXTRACT(YEAR FROM created_at) = ?", userID, req.Month, req.Year).
						Scan(&actualValue)
				case "LOGISTICS_COD":
					tx.WithContext(ctx).Table("finance_transactions").
						Select("COALESCE(SUM(amount), 0)").
						Where("created_by = ? AND status = 'completed' AND flow = 'inbound' AND EXTRACT(MONTH FROM transaction_date) = ? AND EXTRACT(YEAR FROM transaction_date) = ?", userID, req.Month, req.Year).
						Scan(&actualValue)
				case "LOGISTICS_ORDER_COUNT":
					var count int64
					tx.WithContext(ctx).Table("orders").
						Where("delivery_staff_id = ? AND delivery_status = 'delivered' AND EXTRACT(MONTH FROM updated_at) = ? AND EXTRACT(YEAR FROM updated_at) = ?", userID, req.Month, req.Year).
						Count(&count)
					actualValue = float64(count)
				}

				// B. Reward Matching
				for _, rule := range rewardRules {
					if rule.MetricCode == target.MetricCode {
						isMatch := false
						switch rule.ConditionType {
						case ">=":
							if actualValue >= target.TargetValue { isMatch = true }
						case "<=":
							if actualValue <= target.TargetValue { isMatch = true }
						case "==":
							if actualValue == target.TargetValue { isMatch = true }
						}

						if isMatch {
							if rule.RewardType == "PERCENTAGE" {
								commission += actualValue * (rule.RewardValue / 100.0)
							} else if rule.RewardType == "FIXED" {
								kpiBonus += actualValue * rule.RewardValue
							}
						}
					}
				}
			}
		}
	}

	total := contract.BaseSalary + kpiBonus + commission

	payroll := &domain.HRPayroll{
		UserID:      userID,
		Month:       req.Month,
		Year:        req.Year,
		BaseSalary:  contract.BaseSalary,
		KpiBonus:    kpiBonus,
		Commission:  commission,
		TotalSalary: total,
		Status:      "draft",
	}

	if err := s.repo.CreatePayroll(ctx, tx, payroll); err != nil {
		return nil, err
	}

	return payroll, nil
}
