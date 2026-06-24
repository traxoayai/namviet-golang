package postgres

import (
	"context"
	"github.com/namvieterp/backend/internal/core/domain"
	"gorm.io/gorm"
)

type HRPayrollsRepository interface {
	CreatePayroll(ctx context.Context, tx *gorm.DB, payroll *domain.HRPayroll) error
	GetPayrollByUserAndMonth(ctx context.Context, tx *gorm.DB, userID string, month, year int) (*domain.HRPayroll, error)
	GetActiveContract(ctx context.Context, tx *gorm.DB, userID string) (*domain.HRContract, error)
}

type hrPayrollsRepository struct{}

func NewHRPayrollsRepository() HRPayrollsRepository {
	return &hrPayrollsRepository{}
}

func (r *hrPayrollsRepository) CreatePayroll(ctx context.Context, tx *gorm.DB, payroll *domain.HRPayroll) error {
	return tx.Create(payroll).Error
}

func (r *hrPayrollsRepository) GetPayrollByUserAndMonth(ctx context.Context, tx *gorm.DB, userID string, month, year int) (*domain.HRPayroll, error) {
	var pr domain.HRPayroll
	err := tx.Where("user_id = ? AND month = ? AND year = ?", userID, month, year).First(&pr).Error
	if err != nil {
		return nil, err
	}
	return &pr, nil
}

func (r *hrPayrollsRepository) GetActiveContract(ctx context.Context, tx *gorm.DB, userID string) (*domain.HRContract, error) {
	var c domain.HRContract
	err := tx.Where("user_id = ? AND status = 'active'", userID).First(&c).Error
	if err != nil {
		return nil, err
	}
	return &c, nil
}
