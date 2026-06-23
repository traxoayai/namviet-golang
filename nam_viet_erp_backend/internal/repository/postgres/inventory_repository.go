package postgres

import (
	"context"
	"errors"

	"github.com/namvieterp/backend/internal/core/domain"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type InventoryRepository interface {
	GetProductUnit(ctx context.Context, tx *gorm.DB, productID int64, uom string) (*domain.ProductUnit, error)
	GetBatchesForDeduction(ctx context.Context, tx *gorm.DB, warehouseID int64, productID int64) ([]domain.InventoryBatch, error)
	UpdateInventoryBatchQuantity(ctx context.Context, tx *gorm.DB, id int64, newQty float64) error
	CreateInventoryTransaction(ctx context.Context, tx *gorm.DB, trans *domain.InventoryTransaction) error
	GetOrCreateBatch(ctx context.Context, tx *gorm.DB, batch *domain.Batch) error
	AddInventoryBatchQuantity(ctx context.Context, tx *gorm.DB, warehouseID, productID, batchID int64, qty float64) error
	GetTotalStock(ctx context.Context, tx *gorm.DB, warehouseID int64, productID int64) (float64, error)
}

type inventoryRepository struct{}

func NewInventoryRepository() InventoryRepository {
	return &inventoryRepository{}
}

func (r *inventoryRepository) GetProductUnit(ctx context.Context, tx *gorm.DB, productID int64, uom string) (*domain.ProductUnit, error) {
	var unit domain.ProductUnit
	err := tx.WithContext(ctx).Where("product_id = ? AND unit_name = ?", productID, uom).First(&unit).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// If not found, maybe fallback to conversion_rate = 1 if it's the base unit, but here we require strict match
			return nil, err
		}
		return nil, err
	}
	return &unit, nil
}

func (r *inventoryRepository) GetTotalStock(ctx context.Context, tx *gorm.DB, warehouseID int64, productID int64) (float64, error) {
	var total float64
	err := tx.WithContext(ctx).Model(&domain.InventoryBatch{}).
		Where("warehouse_id = ? AND product_id = ?", warehouseID, productID).
		Select("COALESCE(SUM(quantity), 0)").Scan(&total).Error
	return total, err
}

func (r *inventoryRepository) GetBatchesForDeduction(ctx context.Context, tx *gorm.DB, warehouseID int64, productID int64) ([]domain.InventoryBatch, error) {
	var batches []domain.InventoryBatch
	// Join batches to order by expiry_date, apply Row Lock
	err := tx.WithContext(ctx).
		Preload("Batch").
		Joins("JOIN batches b ON b.id = inventory_batches.batch_id").
		Where("inventory_batches.warehouse_id = ? AND inventory_batches.product_id = ? AND inventory_batches.quantity > 0", warehouseID, productID).
		Order("b.expiry_date ASC, inventory_batches.id ASC").
		Clauses(clause.Locking{Strength: "UPDATE"}).
		Find(&batches).Error
	return batches, err
}

func (r *inventoryRepository) UpdateInventoryBatchQuantity(ctx context.Context, tx *gorm.DB, id int64, newQty float64) error {
	return tx.WithContext(ctx).Model(&domain.InventoryBatch{}).Where("id = ?", id).Update("quantity", newQty).Error
}

func (r *inventoryRepository) CreateInventoryTransaction(ctx context.Context, tx *gorm.DB, trans *domain.InventoryTransaction) error {
	return tx.WithContext(ctx).Create(trans).Error
}

func (r *inventoryRepository) GetOrCreateBatch(ctx context.Context, tx *gorm.DB, batch *domain.Batch) error {
	var existing domain.Batch
	err := tx.WithContext(ctx).Where("product_id = ? AND batch_code = ?", batch.ProductID, batch.BatchCode).First(&existing).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return tx.WithContext(ctx).Create(batch).Error
		}
		return err
	}
	batch.ID = existing.ID
	return nil
}

func (r *inventoryRepository) AddInventoryBatchQuantity(ctx context.Context, tx *gorm.DB, warehouseID, productID, batchID int64, qty float64) error {
	var invBatch domain.InventoryBatch
	err := tx.WithContext(ctx).
		Where("warehouse_id = ? AND product_id = ? AND batch_id = ?", warehouseID, productID, batchID).
		Clauses(clause.Locking{Strength: "UPDATE"}).
		First(&invBatch).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			invBatch = domain.InventoryBatch{
				WarehouseID: warehouseID,
				ProductID:   productID,
				BatchID:     batchID,
				Quantity:    qty,
			}
			return tx.WithContext(ctx).Create(&invBatch).Error
		}
		return err
	}

	return tx.WithContext(ctx).Model(&invBatch).Update("quantity", invBatch.Quantity+qty).Error
}
