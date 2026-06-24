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

	// Calculate commission (Mocked integration with Orders)
	commission := 0.0 // Could be query from orders where staff_id = userID and month = req.Month
	kpiBonus := 0.0

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
