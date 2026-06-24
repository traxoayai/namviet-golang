package services

import (
	"context"
	"fmt"
	"strconv"
	"time"

	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/repository/postgres"
	"gorm.io/gorm"
)

type OrderService interface {
	CreateSalesOrder(ctx context.Context, tx *gorm.DB, req domain.CreateOrderRequest, userID string) (*domain.Order, error)
}

type orderService struct {
	repo         postgres.OrderRepository
	inventorySvc InventoryService
	financeSvc   FinanceService
	promoSvc     PromotionService
}

func NewOrderService(repo postgres.OrderRepository, invSvc InventoryService, finSvc FinanceService, promoSvc PromotionService) OrderService {
	return &orderService{
		repo:         repo,
		inventorySvc: invSvc,
		financeSvc:   finSvc,
		promoSvc:     promoSvc,
	}
}

func (s *orderService) CreateSalesOrder(ctx context.Context, tx *gorm.DB, req domain.CreateOrderRequest, userID string) (*domain.Order, error) {
	var totalAmount float64
	var discountAmount float64

	// 1. Calculate items total & build validation items
	var valItems []domain.ValidateStockItem
	for _, item := range req.Items {
		totalAmount += item.Quantity * item.UnitPrice
		valItems = append(valItems, domain.ValidateStockItem{
			ProductID: item.ProductID,
			Uom:       item.Uom,
			Quantity:  item.Quantity,
		})
	}

	// 2. Apply Voucher if exists
	if req.VoucherCode != "" {
		res, err := s.promoSvc.VerifyVoucher(ctx, tx, domain.VerifyPromotionRequest{
			VoucherCodes: []string{req.VoucherCode},
			CustomerID:   req.CustomerID,
			OrderValue:   totalAmount,
		})
		if err != nil {
			return nil, fmt.Errorf("lỗi mã khuyến mãi: %v", err)
		}
		discountAmount = res.DiscountAmount
	}

	finalAmount := totalAmount - discountAmount

	// 3. Validate Stock Availability (Cross-module call)
	valReq := domain.ValidateStockRequest{
		WarehouseID: req.WarehouseID,
		Items:       valItems,
	}
	if err := s.inventorySvc.ValidateStockAvailability(ctx, tx, valReq); err != nil {
		return nil, fmt.Errorf("kiểm tra tồn kho thất bại: %v", err)
	}

	// 4. Create Order Header
	order := &domain.Order{
		OrderCode:      fmt.Sprintf("SO-%d", time.Now().UnixNano()),
		CustomerID:     req.CustomerID,
		TotalAmount:    totalAmount,
		DiscountAmount: discountAmount,
		FinalAmount:    finalAmount,
		Status:         "completed", // Auto-complete for now
		PaymentMethod:  req.PaymentMethod,
		PaymentStatus:  "unpaid",
	}

	if err := s.repo.CreateOrder(ctx, tx, order); err != nil {
		return nil, err
	}

	// 5. Create Order Items
	var orderItems []domain.OrderItem
	for _, reqItem := range req.Items {
		orderItems = append(orderItems, domain.OrderItem{
			OrderID:          order.ID,
			ProductID:        reqItem.ProductID,
			Uom:              reqItem.Uom,
			Quantity:         reqItem.Quantity,
			ConversionFactor: 1, // Need to get this from DB actually
			UnitPrice:        reqItem.UnitPrice,
			TotalPrice:       reqItem.Quantity * reqItem.UnitPrice,
		})
	}
	if err := s.repo.CreateOrderItems(ctx, tx, orderItems); err != nil {
		return nil, err
	}

	// 6. Deduct Stock if Confirmed/Completed (FEFO logic)
	if order.Status == "confirmed" || order.Status == "completed" {
		deductReq := domain.DeductStockRequest{
			WarehouseID: req.WarehouseID,
			Items:       valItems,
		}
		if err := s.inventorySvc.DeductStockFEFO(ctx, tx, deductReq, userID); err != nil {
			return nil, fmt.Errorf("lỗi xuất kho: %v", err)
		}
	}

	// 7. Finance / Payment Integration
	if req.PaymentMethod == "cash" {
		reqTrans := domain.CreateTransactionRequest{
			Flow:          "in",
			Amount:        finalAmount,
			FundAccountID: 1, // hardcode tạm account_id 1
			RefType:       "ORDER",
			RefID:         strconv.FormatInt(order.ID, 10),
			Description:   "Thanh toán đơn hàng",
		}
		if err := s.financeSvc.CreateTransaction(ctx, tx, reqTrans, userID); err != nil {
			return nil, fmt.Errorf("lỗi ghi nhận thanh toán: %v", err)
		}
		order.PaymentStatus = "paid"
		tx.Model(&domain.Order{}).Where("id = ?", order.ID).Update("payment_status", "paid")
	}

	return order, nil
}
