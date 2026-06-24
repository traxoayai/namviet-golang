package postgres

import (
	"context"

	"github.com/namvieterp/backend/internal/core/domain"
	"gorm.io/gorm"
)

type LogisticsRepository interface {
	GetOrderForShipping(ctx context.Context, tx *gorm.DB, orderID string) (*domain.Order, error)
	UpdateOrderShippingStatus(ctx context.Context, tx *gorm.DB, orderID string, trackingCode string, status string) error
	GetOrderByTrackingCode(ctx context.Context, tx *gorm.DB, trackingCode string) (*domain.Order, error)
}

type logisticsRepository struct{}

func NewLogisticsRepository() LogisticsRepository {
	return &logisticsRepository{}
}

func (r *logisticsRepository) GetOrderForShipping(ctx context.Context, tx *gorm.DB, orderID string) (*domain.Order, error) {
	var order domain.Order
	err := tx.WithContext(ctx).Preload("Items").Where("id = ?", orderID).First(&order).Error
	return &order, err
}

// UpdateOrderShippingStatus updates the shipping status and tracking code
func (r *logisticsRepository) UpdateOrderShippingStatus(ctx context.Context, tx *gorm.DB, orderID string, trackingCode string, status string) error {
	return tx.WithContext(ctx).Model(&domain.Order{}).Where("id = ?", orderID).
		Updates(map[string]interface{}{
			"tracking_code": trackingCode,
			"delivery_status": status,
		}).Error
}

func (r *logisticsRepository) GetOrderByTrackingCode(ctx context.Context, tx *gorm.DB, trackingCode string) (*domain.Order, error) {
	var order domain.Order
	err := tx.WithContext(ctx).Where("tracking_code = ?", trackingCode).First(&order).Error
	if err != nil {
		return nil, err
	}
	return &order, nil
}
