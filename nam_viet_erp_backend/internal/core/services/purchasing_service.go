package services

import (
	"context"
	"errors"

	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/repository/postgres"
	"gorm.io/gorm"
)

type PurchasingService interface {
	CreatePurchaseOrder(ctx context.Context, tx *gorm.DB, req domain.CreatePurchaseOrderRequest) (*domain.PurchaseOrder, error)
	AutoReplenishMinMax(ctx context.Context, tx *gorm.DB, warehouseID int64, userID string) (*domain.AutoReplenishResponse, error)
}

type purchasingService struct {
	repo postgres.PurchasingRepository
}

func NewPurchasingService(repo postgres.PurchasingRepository) PurchasingService {
	return &purchasingService{repo: repo}
}

func (s *purchasingService) CreatePurchaseOrder(ctx context.Context, tx *gorm.DB, req domain.CreatePurchaseOrderRequest) (*domain.PurchaseOrder, error) {
	po := &domain.PurchaseOrder{
		SupplierID:     req.SupplierID,
		DeliveryStatus: "pending",
		PaymentStatus:  "unpaid",
	}

	var totalAmount float64
	var poItems []domain.PurchaseOrderItem

	for _, itemReq := range req.Items {
		prodInfo, err := s.repo.GetProductDetails(ctx, tx, itemReq.ProductID)
		if err != nil {
			return nil, errors.New("không lấy được thông tin sản phẩm")
		}

		unitPrice := itemReq.UnitPrice
		if itemReq.IsBonus {
			unitPrice = 0 // Hàng tặng thì giá bằng 0
		}

		convFactor := 1.0
		if itemReq.Unit == prodInfo.WholesaleUnit && prodInfo.ItemsPerCarton > 0 {
			convFactor = float64(prodInfo.ItemsPerCarton)
		}

		baseQty := itemReq.QuantityOrdered * convFactor

		poItems = append(poItems, domain.PurchaseOrderItem{
			ProductID:        itemReq.ProductID,
			QuantityOrdered:  itemReq.QuantityOrdered,
			Unit:             itemReq.Unit,
			ConversionFactor: convFactor,
			BaseQuantity:     baseQty,
			UnitPrice:        unitPrice,
			IsBonus:          itemReq.IsBonus,
		})

		totalAmount += (itemReq.QuantityOrdered * unitPrice)
	}

	po.Items = poItems
	po.TotalAmount = totalAmount

	if err := s.repo.CreatePurchaseOrder(ctx, tx, po); err != nil {
		return nil, err
	}

	return po, nil
}

func (s *purchasingService) AutoReplenishMinMax(ctx context.Context, tx *gorm.DB, warehouseID int64, userID string) (*domain.AutoReplenishResponse, error) {
	products, err := s.repo.FindProductsBelowMinStock(ctx, tx, warehouseID)
	if err != nil {
		return nil, err
	}

	if len(products) == 0 {
		return &domain.AutoReplenishResponse{Message: "Không có sản phẩm nào dưới định mức tối thiểu", CreatedPOCount: 0}, nil
	}

	// Group by Supplier
	supplierMap := make(map[int64][]domain.ProductReplenishDTO)
	for _, p := range products {
		supplierMap[p.SupplierID] = append(supplierMap[p.SupplierID], p)
	}

	var generatedPOs []domain.AutoReplenishPODTO

	for supplierID, items := range supplierMap {
		po := &domain.PurchaseOrder{
			OrderCode:      fmt.Sprintf("PO-AUTO-%d-%d", time.Now().Unix(), supplierID),
			SupplierID:     supplierID,
			DeliveryStatus: "draft",
			PaymentStatus:  "unpaid",
			Note:           "Đơn dự trù tự động (Dưới mức tồn Min)",
		}
		
		if err := tx.WithContext(ctx).Create(po).Error; err != nil {
			return nil, err
		}

		var poItems []domain.PurchaseOrderItem
		var dtoItems []domain.AutoReplenishItemDTO
		totalAmount := 0.0

		for _, item := range items {
			qtyOrdered := float64(item.QuantityNeeded)
			baseQty := qtyOrdered * item.ConversionFactor
			
			poItem := domain.PurchaseOrderItem{
				PurchaseOrderID:  po.ID,
				ProductID:        item.ProductID,
				QuantityOrdered:  qtyOrdered,
				Unit:             item.UnitName,
				UnitPrice:        item.UnitPrice,
				ConversionFactor: item.ConversionFactor,
				BaseQuantity:     baseQty,
				IsBonus:          false,
			}
			poItems = append(poItems, poItem)
			
			dtoItems = append(dtoItems, domain.AutoReplenishItemDTO{
				ProductID:           item.ProductID,
				QuantityOrdered:     item.QuantityNeeded,
				Unit:                item.UnitName,
				UnitPrice:           item.UnitPrice,
				ConversionFactor:    item.ConversionFactor,
				BaseQuantity:        baseQty,
				CurrentStockBase:    item.CurrentStockBase,
				AvgMonthlySalesBase: item.AvgMonthlySalesBase,
			})
			
			totalAmount += (qtyOrdered * item.UnitPrice)
		}

		if err := s.repo.CreatePurchaseOrderItems(ctx, tx, poItems); err != nil {
			return nil, err
		}

		po.TotalAmount = totalAmount
		po.FinalAmount = totalAmount
		if err := tx.WithContext(ctx).Save(po).Error; err != nil {
			return nil, err
		}

		generatedPOs = append(generatedPOs, domain.AutoReplenishPODTO{
			ID:             po.ID,
			OrderCode:      po.OrderCode,
			SupplierID:     supplierID,
			DeliveryStatus: po.DeliveryStatus,
			PaymentStatus:  po.PaymentStatus,
			TotalAmount:    po.TotalAmount,
			FinalAmount:    po.FinalAmount,
			Items:          dtoItems,
		})
	}

	return &domain.AutoReplenishResponse{
		Message:        "Tạo đơn dự trù thành công",
		CreatedPOCount: len(generatedPOs),
		GeneratedPOs:   generatedPOs,
	}, nil
}
