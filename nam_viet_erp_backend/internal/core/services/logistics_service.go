package services

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"os"

	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/repository/postgres"
	"gorm.io/gorm"
)

type LogisticsService interface {
	CreateShippingOrder(ctx context.Context, tx *gorm.DB, orderID int64) (string, error)
	HandleGHNWebhook(ctx context.Context, tx *gorm.DB, signature string, payloadBody []byte) error
}

type logisticsService struct {
	repo   postgres.LogisticsRepository
	crmSvc CRMService
}

func NewLogisticsService(repo postgres.LogisticsRepository, crmSvc CRMService) LogisticsService {
	return &logisticsService{repo: repo, crmSvc: crmSvc}
}

func (s *logisticsService) CreateShippingOrder(ctx context.Context, tx *gorm.DB, orderID int64) (string, error) {
	order, err := s.repo.GetOrderForShipping(ctx, tx, orderID)
	if err != nil {
		return "", errors.New("không tìm thấy đơn hàng")
	}

	if order.DeliveryStatus != "pending" && order.DeliveryStatus != "" {
		return "", errors.New("đơn hàng này đã được tạo vận đơn")
	}

	ghnToken := os.Getenv("GHN_TOKEN")
	if ghnToken == "" {
		// Mock logic if GHN_TOKEN is missing to keep the system running
		mockTrackingCode := fmt.Sprintf("GHN-%d", orderID)
		err = s.repo.UpdateOrderShippingStatus(ctx, tx, orderID, mockTrackingCode, "shipping")
		return mockTrackingCode, err
	}

	// Real GHN API request (simplified)
	ghnReq := domain.GHNCreateOrderRequest{
		ToName:  "Khách hàng",
		ToPhone: "0900000000",
		Weight:  1000,
	}

	reqBody, _ := json.Marshal(ghnReq)
	req, _ := http.NewRequest("POST", "https://dev-online-gateway.ghn.vn/shiip/public-api/v2/shipping-order/create", bytes.NewBuffer(reqBody))
	req.Header.Set("Token", ghnToken)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return "", errors.New("lỗi khi gọi API GHN")
	}

	// For demonstration, let's just generate a code
	trackingCode := fmt.Sprintf("REAL-GHN-%d", orderID)

	err = s.repo.UpdateOrderShippingStatus(ctx, tx, orderID, trackingCode, "shipping")
	if err != nil {
		return "", err
	}

	return trackingCode, nil
}

func (s *logisticsService) HandleGHNWebhook(ctx context.Context, tx *gorm.DB, signature string, payloadBody []byte) error {
	secret := os.Getenv("GHN_WEBHOOK_SECRET")
	if secret != "" {
		h := hmac.New(sha256.New, []byte(secret))
		h.Write(payloadBody)
		expectedSig := hex.EncodeToString(h.Sum(nil))
		
		if expectedSig != signature {
			return errors.New("chữ ký webhook không hợp lệ")
		}
	}

	var payload domain.GHNWebhookPayload
	if err := json.Unmarshal(payloadBody, &payload); err != nil {
		return err
	}

	order, err := s.repo.GetOrderByTrackingCode(ctx, tx, payload.OrderCode)
	if err != nil {
		return errors.New("không tìm thấy tracking_code trong hệ thống")
	}

	if order.DeliveryStatus == "delivered" {
		// Idempotency: Already processed
		return nil
	}

	// Map GHN status to our status
	newStatus := order.DeliveryStatus
	if payload.Status == "delivered" {
		newStatus = "delivered"
		// Grant Loyalty points asynchronously or synchronously depending on needs
		go func(oID int64, cID int64, amt float64) {
			bgCtx := context.Background()
			// Open a new DB session for background job since tx will be committed
			bgTx := tx.Session(&gorm.Session{}).Begin()
			defer func() {
				if r := recover(); r != nil {
					bgTx.Rollback()
				}
			}()
			
			// Attempt to earn loyalty points
			err := s.crmSvc.EarnLoyaltyPoints(bgCtx, bgTx, domain.EarnLoyaltyRequest{
				CustomerID: cID,
				Amount:     amt,
				OrderID:    oID,
			})
			if err == nil {
				bgTx.Commit()
			} else {
				bgTx.Rollback()
			}
		}(order.ID, order.CustomerID, order.TotalAmount)
	}

	if newStatus != order.DeliveryStatus {
		return s.repo.UpdateOrderShippingStatus(ctx, tx, order.ID, payload.OrderCode, newStatus)
	}

	return nil
}
