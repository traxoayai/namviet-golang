package handlers

import (
	"io"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/core/services"
	"gorm.io/gorm"
)

type LogisticsHandler struct {
	db        *gorm.DB
	logisSvc  services.LogisticsService
}

func NewLogisticsHandler(db *gorm.DB, logisSvc services.LogisticsService) *LogisticsHandler {
	return &LogisticsHandler{db: db, logisSvc: logisSvc}
}

// CreateShippingOrder godoc
// @Summary Tạo vận đơn giao hàng
// @Description Gửi API sang hãng vận chuyển để tạo mã vận đơn
// @Tags Logistics
// @Produce json
// @Param id path int true "Order ID"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Router /api/v1/logistics/orders/{id}/shipping [post]
func (h *LogisticsHandler) CreateShippingOrder(c *gin.Context) {
	orderID := c.Param("id")
	if orderID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid order ID"})
		return
	}

	tx := h.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	trackingCode, err := h.logisSvc.CreateShippingOrder(c.Request.Context(), tx, orderID)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, gin.H{
		"message":       "Tạo vận đơn thành công",
		"tracking_code": trackingCode,
	})
}

// HandleGHNWebhook godoc
// @Summary Webhook nhận trạng thái từ GHN
// @Description Hãng vận chuyển gọi API này để báo cáo trạng thái đơn hàng
// @Tags Logistics
// @Accept json
// @Produce json
// @Router /api/v1/webhooks/logistics/status-update [post]
func (h *LogisticsHandler) HandleGHNWebhook(c *gin.Context) {
	signature := c.GetHeader("X-GHN-Signature")
	
	payloadBody, err := io.ReadAll(c.Request.Body)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot read body"})
		return
	}

	tx := h.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	err = h.logisSvc.HandleGHNWebhook(c.Request.Context(), tx, signature, payloadBody)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, gin.H{"message": "success"})
}

// MarkCODPaid godoc
// @Summary Xác nhận thu tiền COD
// @Description Shipper xác nhận đã thu tiền mặt từ khách
// @Tags Logistics
// @Accept json
// @Produce json
// @Param req body domain.MarkCODPaidRequest true "Payload"
// @Router /api/v1/logistics/mark-cod-paid [post]
func (h *LogisticsHandler) MarkCODPaid(c *gin.Context) {
	var req domain.MarkCODPaidRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dữ liệu không hợp lệ: " + err.Error()})
		return
	}

	shipperID := "system"
	if uid, exists := c.Get("user_id"); exists {
		shipperID = uid.(string)
	}

	tx := h.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	err := h.logisSvc.MarkCODPaid(c.Request.Context(), tx, req.OrderID, shipperID)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, gin.H{"message": "Xác nhận thu tiền thành công"})
}

// RollbackCOD godoc
// @Summary Hủy xác nhận thu tiền COD
// @Description Hủy phiếu thu COD trong trường hợp ấn nhầm
// @Tags Logistics
// @Accept json
// @Produce json
// @Param req body domain.MarkCODPaidRequest true "Payload"
// @Router /api/v1/logistics/rollback-cod [post]
func (h *LogisticsHandler) RollbackCOD(c *gin.Context) {
	var req domain.MarkCODPaidRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dữ liệu không hợp lệ: " + err.Error()})
		return
	}

	shipperID := "system"
	if uid, exists := c.Get("user_id"); exists {
		shipperID = uid.(string)
	}

	tx := h.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	err := h.logisSvc.RollbackCOD(c.Request.Context(), tx, req.OrderID, shipperID)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, gin.H{"message": "Hủy xác nhận thu tiền thành công"})
}
