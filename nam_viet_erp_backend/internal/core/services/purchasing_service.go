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
}

type purchasingService struct {
	repo postgres.PurchasingRepository
}

func NewPurchasingService(repo postgres.PurchasingRepository) PurchasingService {
	return &purchasingService{repo: repo}
}

func (s *purchasingService) CreatePurchaseOrder(ctx context.Context, tx *gorm.DB, req domain.CreatePurchaseOrderRequest) (*domain.PurchaseOrder, error) {
	po := &domain.PurchaseOrder{
		SupplierID: req.SupplierID,
		Status:     "pending",
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
