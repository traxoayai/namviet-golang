package postgres

import (
	"context"

	"github.com/namvieterp/backend/internal/core/domain"
	"gorm.io/gorm"
)

type CRMRepository interface {
	GetCustomerByID(ctx context.Context, tx *gorm.DB, customerID int64) (*domain.Customer, error)
	UpdateCustomerLoyaltyPoints(ctx context.Context, tx *gorm.DB, customerID int64, newPoints int) error
}

type crmRepository struct{}

func NewCRMRepository() CRMRepository {
	return &crmRepository{}
}

func (r *crmRepository) GetCustomerByID(ctx context.Context, tx *gorm.DB, customerID int64) (*domain.Customer, error) {
	var customer domain.Customer
	err := tx.WithContext(ctx).Where("id = ?", customerID).First(&customer).Error
	return &customer, err
}

func (r *crmRepository) UpdateCustomerLoyaltyPoints(ctx context.Context, tx *gorm.DB, customerID int64, newPoints int) error {
	return tx.WithContext(ctx).Model(&domain.Customer{}).Where("id = ?", customerID).Update("loyalty_points", newPoints).Error
}
