package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/core/services"
	"gorm.io/gorm"
)

type OrderHandler struct {
	db           *gorm.DB
	orderService services.OrderService
}

func NewOrderHandler(db *gorm.DB, orderSvc services.OrderService) *OrderHandler {
	return &OrderHandler{db: db, orderService: orderSvc}
}

// CreateSalesOrder godoc
// @Summary Tạo đơn bán hàng
// @Description Tạo đơn hàng, kiểm tra voucher, trừ tồn kho và ghi nhận thanh toán
// @Tags Orders
// @Accept json
// @Produce json
// @Param req body domain.CreateOrderRequest true "Create order request payload"
// @Success 200 {object} domain.Order
// @Failure 400 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/orders [post]
func (h *OrderHandler) CreateSalesOrder(c *gin.Context) {
	var req domain.CreateOrderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dữ liệu đầu vào không hợp lệ: " + err.Error()})
		return
	}

	userID := "system"
	if uid, exists := c.Get("user_id"); exists {
		userID = uid.(string)
	}

	// 1. Mở Global Transaction
	tx := h.db.Begin()
	if tx.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi hệ thống khi mở transaction"})
		return
	}

	// 2. Defer Rollback nếu panic hoặc lỗi
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 3. Gọi Service nghiệp vụ
	order, err := h.orderService.CreateSalesOrder(c.Request.Context(), tx, req, userID)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 4. Commit Transaction
	if err := tx.Commit().Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi commit transaction: " + err.Error()})
		return
	}

	// 5. Trigger Async Event (EventBus)
	// eventBus.Publish("order_created", order)

	c.JSON(http.StatusOK, order)
}

// MarkDelivered godoc
// @Summary Đánh dấu đơn hàng đã giao
// @Description Đánh dấu đơn hàng đã giao thành công cho khách, dùng cho Giao vận & KPI
// @Tags Orders
// @Accept json
// @Produce json
// @Param id path string true "Order ID"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/orders/{id}/mark-delivered [post]
func (h *OrderHandler) MarkDelivered(c *gin.Context) {
	orderID := c.Param("id")
	if orderID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Thiếu Order ID"})
		return
	}

	tx := h.db.Begin()
	if tx.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi hệ thống khi mở transaction"})
		return
	}
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	if err := h.orderService.MarkDelivered(c.Request.Context(), tx, orderID); err != nil {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := tx.Commit().Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi commit transaction: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Đã cập nhật trạng thái giao hàng thành công"})
}
