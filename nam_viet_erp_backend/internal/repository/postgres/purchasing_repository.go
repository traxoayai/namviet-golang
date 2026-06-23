package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/namvieterp/backend/internal/core/domain"
	"gorm.io/gorm"
)

type PurchasingRepository interface {
	CreatePurchaseOrder(ctx context.Context, tx *gorm.DB, order *domain.PurchaseOrder) error
	CreatePurchaseOrderItems(ctx context.Context, tx *gorm.DB, items []domain.PurchaseOrderItem) error
	GetProductDetails(ctx context.Context, tx *gorm.DB, productID int64) (*domain.ValidateStockItem, error)
	FindProductsBelowMinStock(ctx context.Context, tx *gorm.DB, warehouseID int64) ([]domain.ProductReplenishDTO, error)
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

func (r *purchasingRepository) CreatePurchaseOrderItems(ctx context.Context, tx *gorm.DB, items []domain.PurchaseOrderItem) error {
	return tx.WithContext(ctx).Create(&items).Error
}

func (r *purchasingRepository) FindProductsBelowMinStock(ctx context.Context, tx *gorm.DB, warehouseID int64) ([]domain.ProductReplenishDTO, error) {
	var results []domain.ProductReplenishDTO

	query := `
		SELECT 
			p.id as product_id,
			p.distributor_id as supplier_id,
			u.unit_name as unit_name,
			u.conversion_rate as conversion_factor,
			(COALESCE(p.actual_cost, 0) * u.conversion_rate) as unit_price,
			CEIL((inv.max_stock - inv.stock_quantity)::NUMERIC / u.conversion_rate)::INTEGER as quantity_needed,
			inv.stock_quantity as current_stock_base,
			COALESCE(
                (
                    SELECT ROUND(SUM(oi.quantity * COALESCE(oi.conversion_factor, 1)) / 3.0, 1)
                    FROM order_items oi
                    JOIN orders o ON oi.order_id = o.id
                    WHERE oi.product_id = p.id
                      AND o.status NOT IN ('CANCELLED', 'DRAFT')
                      AND o.created_at >= NOW() - INTERVAL '3 months'
                ), 0
            ) as avg_monthly_sales_base
		FROM product_inventory inv
		JOIN products p ON inv.product_id = p.id
		JOIN LATERAL (
			SELECT unit_name, conversion_rate
			FROM product_units pu
			WHERE pu.product_id = p.id 
			  AND pu.unit_type = 'wholesale'
			ORDER BY pu.conversion_rate DESC
			LIMIT 1
		) u ON true
		WHERE inv.warehouse_id = ?
		  AND p.status = 'active'
		  AND p.distributor_id IS NOT NULL
		  AND inv.min_stock > 0 
		  AND inv.max_stock > 0
		  AND inv.stock_quantity <= inv.min_stock
		  AND inv.max_stock > inv.stock_quantity
		  AND NOT EXISTS (
			  SELECT 1 
			  FROM purchase_order_items poi
			  JOIN purchase_orders po ON poi.po_id = po.id
			  WHERE poi.product_id = p.id
				AND po.delivery_status IN ('draft', 'pending', 'ordered', 'shipping', 'partially_delivered')
		  )
	`

	if err := tx.WithContext(ctx).Raw(query, warehouseID).Scan(&results).Error; err != nil {
		return nil, err
	}

	return results, nil
}
