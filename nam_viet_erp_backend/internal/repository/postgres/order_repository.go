package postgres

import (
	"context"

	"github.com/namvieterp/backend/internal/core/domain"
	"gorm.io/gorm"
)

type OrderRepository interface {
	GetPromotionByCode(ctx context.Context, tx *gorm.DB, code string) (*domain.Promotion, error)
	CreateOrder(ctx context.Context, tx *gorm.DB, order *domain.Order) error
	CreateOrderItems(ctx context.Context, tx *gorm.DB, items []domain.OrderItem) error
}

type orderRepository struct{}

func NewOrderRepository() OrderRepository {
	return &orderRepository{}
}

func (r *orderRepository) GetPromotionByCode(ctx context.Context, tx *gorm.DB, code string) (*domain.Promotion, error) {
	var promo domain.Promotion
	err := tx.WithContext(ctx).Where("code = ? AND status = 'active'", code).First(&promo).Error
	if err != nil {
		return nil, err
	}
	return &promo, nil
}

func (r *orderRepository) CreateOrder(ctx context.Context, tx *gorm.DB, order *domain.Order) error {
	return tx.WithContext(ctx).Create(order).Error
}

func (r *orderRepository) CreateOrderItems(ctx context.Context, tx *gorm.DB, items []domain.OrderItem) error {
	return tx.WithContext(ctx).Create(&items).Error
}
