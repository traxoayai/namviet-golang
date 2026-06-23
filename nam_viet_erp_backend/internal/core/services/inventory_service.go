package services

import (
	"context"
	"fmt"

	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/repository/postgres"
	"gorm.io/gorm"
)

type InventoryService interface {
	ValidateStockAvailability(ctx context.Context, tx *gorm.DB, req domain.ValidateStockRequest) error
	DeductStockFEFO(ctx context.Context, tx *gorm.DB, req domain.DeductStockRequest, userID string) error
	CreateInventoryReceipt(ctx context.Context, tx *gorm.DB, req domain.CreateReceiptRequest, userID string) error
}

type inventoryService struct {
	repo postgres.InventoryRepository
}

func NewInventoryService(repo postgres.InventoryRepository) InventoryService {
	return &inventoryService{repo: repo}
}

func (s *inventoryService) ValidateStockAvailability(ctx context.Context, tx *gorm.DB, req domain.ValidateStockRequest) error {
	for _, item := range req.Items {
		// 1. Resolve conversion rate
		unit, err := s.repo.GetProductUnit(ctx, tx, item.ProductID, item.Uom)
		if err != nil {
			return fmt.Errorf("không tìm thấy đơn vị tính %s cho sản phẩm %d: %v", item.Uom, item.ProductID, err)
		}
		
		baseQty := item.Quantity * unit.ConversionRate

		// 2. Get total stock for product
		totalStock, err := s.repo.GetTotalStock(ctx, tx, req.WarehouseID, item.ProductID)
		if err != nil {
			return fmt.Errorf("lỗi kiểm tra tồn kho cho sản phẩm %d: %v", item.ProductID, err)
		}

		if totalStock < baseQty {
			return fmt.Errorf("sản phẩm %d thiếu %f (cơ bản) để xuất kho (Hiện có: %f)", item.ProductID, baseQty-totalStock, totalStock)
		}
	}
	return nil
}

func (s *inventoryService) DeductStockFEFO(ctx context.Context, tx *gorm.DB, req domain.DeductStockRequest, userID string) error {
	for _, item := range req.Items {
		// 1. Resolve conversion rate
		unit, err := s.repo.GetProductUnit(ctx, tx, item.ProductID, item.Uom)
		if err != nil {
			return fmt.Errorf("không tìm thấy đơn vị tính %s cho sản phẩm %d", item.Uom, item.ProductID)
		}
		
		remainingBaseQty := item.Quantity * unit.ConversionRate

		// 2. Get Batches (ordered by Expiry Date ASC) with Row Lock
		batches, err := s.repo.GetBatchesForDeduction(ctx, tx, req.WarehouseID, item.ProductID)
		if err != nil {
			return fmt.Errorf("lỗi truy xuất lô hàng: %v", err)
		}

		for _, invBatch := range batches {
			if remainingBaseQty <= 0 {
				break
			}

			deductQty := remainingBaseQty
			if invBatch.Quantity < deductQty {
				deductQty = invBatch.Quantity
			}

			// Update quantity
			err := s.repo.UpdateInventoryBatchQuantity(ctx, tx, invBatch.ID, invBatch.Quantity-deductQty)
			if err != nil {
				return err
			}

			// Create transaction log
			actionGroup := "outbound_order"
			trans := &domain.InventoryTransaction{
				WarehouseID: req.WarehouseID,
				ProductID:   item.ProductID,
				BatchID:     &invBatch.BatchID,
				Type:        "out",
				Quantity:    deductQty,
				CreatedBy:   &userID,
				ActionGroup: &actionGroup,
			}
			if err := s.repo.CreateInventoryTransaction(ctx, tx, trans); err != nil {
				return err
			}

			remainingBaseQty -= deductQty
		}

		if remainingBaseQty > 0 {
			// Rollback will be triggered by caller
			return fmt.Errorf("sản phẩm %d thiếu %f tồn kho không thể xuất", item.ProductID, remainingBaseQty)
		}
	}

	return nil
}

func (s *inventoryService) CreateInventoryReceipt(ctx context.Context, tx *gorm.DB, req domain.CreateReceiptRequest, userID string) error {
	for _, item := range req.Items {
		// 1. Get or Create Batch
		batch := &domain.Batch{
			ProductID:    item.ProductID,
			BatchCode:    item.BatchCode,
			ExpiryDate:   item.ExpiryDate,
			InboundPrice: item.UnitPrice,
		}
		if err := s.repo.GetOrCreateBatch(ctx, tx, batch); err != nil {
			return fmt.Errorf("lỗi tạo lô hàng %s: %v", batch.BatchCode, err)
		}

		// 2. Add Quantity to Inventory Batch
		err := s.repo.AddInventoryBatchQuantity(ctx, tx, req.WarehouseID, item.ProductID, batch.ID, item.Quantity)
		if err != nil {
			return fmt.Errorf("lỗi cộng tồn kho: %v", err)
		}

		// 3. Create transaction log
		actionGroup := "inbound_receipt"
		trans := &domain.InventoryTransaction{
			WarehouseID: req.WarehouseID,
			ProductID:   item.ProductID,
			BatchID:     &batch.ID,
			Type:        "in",
			Quantity:    item.Quantity,
			CreatedBy:   &userID,
			Note:        &req.Note,
			ActionGroup: &actionGroup,
			UnitPrice:   item.UnitPrice,
			TotalValue:  item.Quantity * item.UnitPrice,
		}
		if err := s.repo.CreateInventoryTransaction(ctx, tx, trans); err != nil {
			return err
		}
	}
	return nil
}
