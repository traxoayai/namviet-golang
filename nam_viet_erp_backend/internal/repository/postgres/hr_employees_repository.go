package postgres

import (
	"context"
	"github.com/namvieterp/backend/internal/core/domain"
	"gorm.io/gorm"
)

type HREmployeesRepository interface {
	GetEmployees(ctx context.Context, tx *gorm.DB, limit, offset int) ([]domain.Employee, int64, error)
	GetEmployeeProfile(ctx context.Context, tx *gorm.DB, userID string) (*domain.EmployeeProfileDTO, error)
}

type hrEmployeesRepository struct{}

func NewHREmployeesRepository() HREmployeesRepository {
	return &hrEmployeesRepository{}
}

func (r *hrEmployeesRepository) GetEmployees(ctx context.Context, tx *gorm.DB, limit, offset int) ([]domain.Employee, int64, error) {
	var employees []domain.Employee
	var total int64

	// Lọc các user có employee_code hoặc role tương ứng nếu cần
	query := tx.Model(&domain.Employee{}).Where("employee_code IS NOT NULL AND employee_code != ''")

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	if err := query.Limit(limit).Offset(offset).Find(&employees).Error; err != nil {
		return nil, 0, err
	}

	return employees, total, nil
}

func (r *hrEmployeesRepository) GetEmployeeProfile(ctx context.Context, tx *gorm.DB, userID string) (*domain.EmployeeProfileDTO, error) {
	var emp domain.Employee
	if err := tx.Where("id = ?", userID).First(&emp).Error; err != nil {
		return nil, err
	}

	var contracts []domain.HRContract
	tx.Where("user_id = ?", userID).Find(&contracts)

	var payrolls []domain.HRPayroll
	tx.Where("user_id = ?", userID).Find(&payrolls)

	return &domain.EmployeeProfileDTO{
		Employee:  emp,
		Contracts: contracts,
		Payrolls:  payrolls,
	}, nil
}
