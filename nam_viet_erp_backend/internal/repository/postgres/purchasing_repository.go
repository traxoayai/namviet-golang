package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/namvieterp/backend/internal/core/domain"
	"gorm.io/gorm"
)

type PurchasingRepository interface {
	CreatePurchaseOrder(ctx context.Context, tx *gorm.DB, po *domain.PurchaseOrder) error
	GetProductDetails(ctx context.Context, tx *gorm.DB, productID int64) (*domain.ValidateStockItem, error)
}

type purchasingRepository struct{}

func NewPurchasingRepository() PurchasingRepository {
	return &purchasingRepository{}
}

func (r *purchasingRepository) CreatePurchaseOrder(ctx context.Context, tx *gorm.DB, po *domain.PurchaseOrder) error {
	// Let gorm auto-generate PO Code via database default or before create hook.
	// For simplicity, we generate it here if not present.
	if po.OrderCode == "" {
		po.OrderCode = fmt.Sprintf("PO-%d", time.Now().Unix())
	}
	return tx.WithContext(ctx).Create(po).Error
}

func (r *purchasingRepository) GetProductDetails(ctx context.Context, tx *gorm.DB, productID int64) (*domain.ValidateStockItem, error) {
	// We reuse ValidateStockItem struct since it contains wholesale_unit and items_per_carton
	var item domain.ValidateStockItem
	err := tx.WithContext(ctx).Table("products").
		Select("id as product_id, sku, base_unit, wholesale_unit, items_per_carton").
		Where("id = ?", productID).
		First(&item).Error
	if err != nil {
		return nil, err
	}
	return &item, nil
}
