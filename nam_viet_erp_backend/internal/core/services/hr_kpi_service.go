package services

import (
	"context"
	"errors"

	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/repository/postgres"
	"gorm.io/gorm"
)

type HRKPIService interface {
	AssignKPITarget(ctx context.Context, tx *gorm.DB, currentUserID string, req domain.AssignKPITargetRequest) (*domain.HRKPITarget, error)
	GetMyKPIProgress(ctx context.Context, tx *gorm.DB, employeeID string, month, year int) (*domain.KPIProgressResponse, error)
	GetAllMetrics(ctx context.Context, tx *gorm.DB) ([]domain.HRKPIMetric, error)
}

type hrKpiService struct {
	repo postgres.HRKPIRepository
}

func NewHRKPIService(repo postgres.HRKPIRepository) HRKPIService {
	return &hrKpiService{repo: repo}
}

func (s *hrKpiService) AssignKPITarget(ctx context.Context, tx *gorm.DB, currentUserID string, req domain.AssignKPITargetRequest) (*domain.HRKPITarget, error) {
	// 1. Fetch current user to check department & permissions
	currentUser, err := s.repo.GetEmployeeByID(ctx, tx, currentUserID)
	if err != nil {
		return nil, errors.New("failed to get current user info")
	}

	// Fetch target user to check department
	targetUser, err := s.repo.GetEmployeeByID(ctx, tx, req.EmployeeID)
	if err != nil {
		return nil, errors.New("failed to get target user info")
	}

	// 2. Fetch current user's roles from user_roles
	type UserRoleInfo struct {
		RoleName string
	}
	var currentRoles []UserRoleInfo
	db := tx
	if err := db.WithContext(ctx).Table("user_roles").
		Select("roles.name as role_name").
		Joins("JOIN roles ON roles.id = user_roles.role_id").
		Where("user_roles.user_id = ?", currentUserID).
		Find(&currentRoles).Error; err != nil {
		return nil, errors.New("failed to check user roles")
	}

	isAdmin := false
	isDepartmentManager := false

	for _, r := range currentRoles {
		if r.RoleName == "Admin" || r.RoleName == "Board of Directors" {
			isAdmin = true
		}
		if r.RoleName == "Department Manager" || r.RoleName == "Department_Manager" {
			isDepartmentManager = true
		}
	}

	// 3. Authorization Logic
	canAssign := false
	if isAdmin {
		canAssign = true
	} else if isDepartmentManager {
		// Check permissions JSONB for {"can_assign_kpi": true}
		if currentUser.Permissions != nil {
			if val, ok := currentUser.Permissions["can_assign_kpi"].(bool); ok && val {
				// Check department match
				if currentUser.DepartmentID != nil && targetUser.DepartmentID != nil {
					if *currentUser.DepartmentID == *targetUser.DepartmentID {
						canAssign = true
					}
				}
			}
		}
	}

	if !canAssign {
		return nil, errors.New("forbidden: you do not have permission to assign KPI to this employee")
	}

	// 4. Create KPI Target
	target := &domain.HRKPITarget{
		EmployeeID:  req.EmployeeID,
		Month:       req.Month,
		Year:        req.Year,
		MetricCode:  req.MetricCode,
		TargetValue: req.TargetValue,
		AssignedBy:  &currentUserID,
	}

	if err := s.repo.CreateTarget(ctx, tx, target); err != nil {
		return nil, err
	}

	return target, nil
}

func (s *hrKpiService) GetMyKPIProgress(ctx context.Context, tx *gorm.DB, employeeID string, month, year int) (*domain.KPIProgressResponse, error) {
	targets, err := s.repo.GetTargetsByEmployee(ctx, tx, employeeID, month, year)
	if err != nil {
		return nil, errors.New("failed to fetch KPI targets")
	}

	metrics, err := s.repo.GetAllMetrics(ctx, tx)
	if err != nil {
		return nil, errors.New("failed to fetch KPI metrics")
	}

	metricNameMap := make(map[string]string)
	for _, m := range metrics {
		metricNameMap[m.Code] = m.Name
	}

	response := &domain.KPIProgressResponse{
		EmployeeID: employeeID,
		Month:      month,
		Year:       year,
		Progresses: []domain.KPIProgressDetail{},
	}

	for _, target := range targets {
		actualValue := 0.0

		// Actual Data Fetcher
		switch target.MetricCode {
		case "SALES_REVENUE":
			tx.WithContext(ctx).Table("orders").
				Select("COALESCE(SUM(final_amount), 0)").
				Where("creator_id = ? AND status = 'completed' AND EXTRACT(MONTH FROM created_at) = ? AND EXTRACT(YEAR FROM created_at) = ?", employeeID, month, year).
				Scan(&actualValue)
		case "LOGISTICS_COD":
			tx.WithContext(ctx).Table("finance_transactions").
				Select("COALESCE(SUM(amount), 0)").
				Where("created_by = ? AND status = 'completed' AND flow = 'inbound' AND EXTRACT(MONTH FROM transaction_date) = ? AND EXTRACT(YEAR FROM transaction_date) = ?", employeeID, month, year).
				Scan(&actualValue)
		case "LOGISTICS_ORDER_COUNT":
			var count int64
			tx.WithContext(ctx).Table("orders").
				Where("delivery_staff_id = ? AND delivery_status = 'delivered' AND EXTRACT(MONTH FROM updated_at) = ? AND EXTRACT(YEAR FROM updated_at) = ?", employeeID, month, year).
				Count(&count)
			actualValue = float64(count)

		case "LOGISTICS_SLA_4H":
			var totalOrders, onTimeOrders int64
			baseQuery := tx.WithContext(ctx).Table("orders").
				Where("delivery_staff_id = ? AND delivery_status = 'delivered' AND delivery_method IN ('cod', 'external_bus') AND EXTRACT(MONTH FROM delivered_at) = ? AND EXTRACT(YEAR FROM delivered_at) = ?", employeeID, month, year)
			baseQuery.Count(&totalOrders)
			baseQuery.Where("EXTRACT(EPOCH FROM (delivered_at - created_at)) <= 14400").Count(&onTimeOrders)
			if totalOrders > 0 {
				actualValue = float64(onTimeOrders) / float64(totalOrders) * 100
			}

		case "LOGISTICS_COD_48H":
			var totalCod, onTimeCod int64
			baseQuery := tx.WithContext(ctx).Table("orders").
				Where("delivery_staff_id = ? AND delivery_status = 'delivered' AND delivery_method = 'cod' AND EXTRACT(MONTH FROM delivered_at) = ? AND EXTRACT(YEAR FROM delivered_at) = ?", employeeID, month, year)
			baseQuery.Count(&totalCod)
			baseQuery.Joins("JOIN finance_transactions ft ON ft.target_id = orders.id OR ft.reference_code = orders.code").
				Where("ft.flow = 'inbound' AND ft.status = 'completed' AND EXTRACT(EPOCH FROM (ft.transaction_date - orders.delivered_at)) <= 172800").
				Count(&onTimeCod)
			if totalCod > 0 {
				actualValue = float64(onTimeCod) / float64(totalCod) * 100
			}

		case "B2B_PAID_REVENUE":
			tx.WithContext(ctx).Table("orders").
				Select("COALESCE(SUM(final_amount), 0)").
				Where("creator_id = ? AND order_type = 'B2B' AND payment_status = 'paid' AND EXTRACT(MONTH FROM created_at) = ? AND EXTRACT(YEAR FROM created_at) = ?", employeeID, month, year).
				Scan(&actualValue)

		case "B2B_RETENTION":
			var totalCustomers, returningCustomers int64
			tx.WithContext(ctx).Table("orders").Select("COUNT(DISTINCT customer_id)").
				Where("creator_id = ? AND order_type = 'B2B' AND EXTRACT(MONTH FROM created_at) = ? AND EXTRACT(YEAR FROM created_at) = ?", employeeID, month, year).
				Scan(&totalCustomers)
			if totalCustomers > 0 {
				tx.WithContext(ctx).Table("orders o1").Select("COUNT(DISTINCT o1.customer_id)").
					Where("o1.creator_id = ? AND o1.order_type = 'B2B' AND EXTRACT(MONTH FROM o1.created_at) = ? AND EXTRACT(YEAR FROM o1.created_at) = ?", employeeID, month, year).
					Where("EXISTS (SELECT 1 FROM orders o2 WHERE o2.customer_id = o1.customer_id AND o2.created_at < date_trunc('month', o1.created_at))").
					Scan(&returningCustomers)
				actualValue = float64(returningCustomers) / float64(totalCustomers) * 100
			}

		case "B2B_SURVEY_RATE":
			actualValue = 0 // TBD: Cần bảng Survey

		case "WH_MINMAX_COMPLIANCE":
			var totalProducts, compliantProducts int64
			tx.WithContext(ctx).Table("product_inventory").
				Where("warehouse_id IN (SELECT id FROM warehouses WHERE manager_id = ?)", employeeID).
				Count(&totalProducts)
			if totalProducts > 0 {
				tx.WithContext(ctx).Table("product_inventory").
					Where("warehouse_id IN (SELECT id FROM warehouses WHERE manager_id = ?) AND stock_quantity >= min_stock AND (max_stock = 0 OR stock_quantity <= max_stock)", employeeID).
					Count(&compliantProducts)
				actualValue = float64(compliantProducts) / float64(totalProducts) * 100
			}

		case "WH_AGING_STOCK":
			var totalStock, agingStock float64
			tx.WithContext(ctx).Table("product_inventory").
				Where("warehouse_id IN (SELECT id FROM warehouses WHERE manager_id = ?) AND stock_quantity > 0", employeeID).
				Select("COALESCE(SUM(stock_quantity), 0)").Scan(&totalStock)
			if totalStock > 0 {
				tx.WithContext(ctx).Table("product_inventory").
					Where("warehouse_id IN (SELECT id FROM warehouses WHERE manager_id = ?) AND stock_quantity > 0 AND updated_at < NOW() - INTERVAL '60 days'", employeeID).
					Select("COALESCE(SUM(stock_quantity), 0)").Scan(&agingStock)
				actualValue = float64(agingStock) / float64(totalStock) * 100
			}

		case "B2B_GROSS_MARGIN":
			var totalRevenue, totalCost float64
			tx.WithContext(ctx).Table("orders").
				Select("COALESCE(SUM(final_amount), 0)").
				Where("creator_id = ? AND order_type = 'B2B' AND status = 'completed' AND EXTRACT(MONTH FROM created_at) = ? AND EXTRACT(YEAR FROM created_at) = ?", employeeID, month, year).
				Scan(&totalRevenue)
			tx.WithContext(ctx).Table("orders").
				Select("COALESCE(SUM(total_amount * 0.8), 0)").
				Where("creator_id = ? AND order_type = 'B2B' AND status = 'completed' AND EXTRACT(MONTH FROM created_at) = ? AND EXTRACT(YEAR FROM created_at) = ?", employeeID, month, year).
				Scan(&totalCost)
			if totalRevenue > 0 {
				actualValue = ((totalRevenue - totalCost) / totalRevenue) * 100
			}

		case "B2B_DSO":
			var totalRevenue, unpaidAmount float64
			tx.WithContext(ctx).Table("orders").
				Select("COALESCE(SUM(final_amount), 0)").
				Where("creator_id = ? AND order_type = 'B2B' AND EXTRACT(MONTH FROM created_at) = ? AND EXTRACT(YEAR FROM created_at) = ?", employeeID, month, year).
				Scan(&totalRevenue)
			tx.WithContext(ctx).Table("orders").
				Select("COALESCE(SUM(final_amount - paid_amount), 0)").
				Where("creator_id = ? AND order_type = 'B2B' AND payment_status = 'unpaid' AND EXTRACT(MONTH FROM created_at) = ? AND EXTRACT(YEAR FROM created_at) = ?", employeeID, month, year).
				Scan(&unpaidAmount)
			if totalRevenue > 0 {
				actualValue = (unpaidAmount / totalRevenue) * 30
			}

		case "B2B_AOV":
			var count int64
			var totalRev float64
			tx.WithContext(ctx).Table("orders").
				Where("creator_id = ? AND order_type = 'B2B' AND EXTRACT(MONTH FROM created_at) = ? AND EXTRACT(YEAR FROM created_at) = ?", employeeID, month, year).
				Count(&count)
			tx.WithContext(ctx).Table("orders").
				Select("COALESCE(SUM(final_amount), 0)").
				Where("creator_id = ? AND order_type = 'B2B' AND EXTRACT(MONTH FROM created_at) = ? AND EXTRACT(YEAR FROM created_at) = ?", employeeID, month, year).
				Scan(&totalRev)
			if count > 0 {
				actualValue = totalRev / float64(count)
			}
		}

		percentage := 0.0
		if target.TargetValue > 0 {
			percentage = (actualValue / target.TargetValue) * 100
		}
		
		isAchieved := false
		if actualValue >= target.TargetValue {
			isAchieved = true
		}

		response.Progresses = append(response.Progresses, domain.KPIProgressDetail{
			MetricCode:  target.MetricCode,
			MetricName:  metricNameMap[target.MetricCode],
			TargetValue: target.TargetValue,
			ActualValue: actualValue,
			IsAchieved:  isAchieved,
			Percentage:  percentage,
		})
	}

	return response, nil
}

func (s *hrKpiService) GetAllMetrics(ctx context.Context, tx *gorm.DB) ([]domain.HRKPIMetric, error) {
	return s.repo.GetAllMetrics(ctx, tx)
}
