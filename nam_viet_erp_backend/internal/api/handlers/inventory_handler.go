package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/core/services"
	"gorm.io/gorm"
)

type InventoryHandler struct {
	db               *gorm.DB
	inventoryService services.InventoryService
}

func NewInventoryHandler(db *gorm.DB, invSvc services.InventoryService) *InventoryHandler {
	return &InventoryHandler{db: db, inventoryService: invSvc}
}

// ValidateStock godoc
// @Summary Kiểm tra tồn kho
// @Description Validate if stock is available for given items and warehouse
// @Tags Inventory
// @Accept json
// @Produce json
// @Param req body domain.ValidateStockRequest true "Stock validation request"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Router /api/v1/inventory/validate [post]
func (h *InventoryHandler) ValidateStock(c *gin.Context) {
	var req domain.ValidateStockRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dữ liệu đầu vào không hợp lệ: " + err.Error()})
		return
	}

	// We use an empty transaction just to wrap the DB for consistent interface, or we can pass h.db directly.
	// Since Validate doesn't write, we don't strictly need Begin().
	err := h.inventoryService.ValidateStockAvailability(c.Request.Context(), h.db, req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Tồn kho hợp lệ"})
}

// DeductStock godoc
// @Summary Trừ tồn kho FEFO
// @Description Trừ tồn kho theo thuật toán FEFO
// @Tags Inventory
// @Accept json
// @Produce json
// @Param req body domain.DeductStockRequest true "Stock deduction request"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/inventory/deduct [post]
func (h *InventoryHandler) DeductStock(c *gin.Context) {
	var req domain.DeductStockRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dữ liệu đầu vào không hợp lệ: " + err.Error()})
		return
	}

	// Fake userID from context (should be set by JWT middleware)
	userID := "system"
	if uid, exists := c.Get("user_id"); exists {
		userID = uid.(string)
	}

	// Bắt đầu Global Transaction
	tx := h.db.Begin()
	if tx.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi hệ thống khi mở transaction"})
		return
	}

	// Phải đảm bảo Rollback nếu có lỗi
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	err := h.inventoryService.DeductStockFEFO(c.Request.Context(), tx, req, userID)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := tx.Commit().Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi commit transaction: " + err.Error()})
		return
	}

	// TODO: Phát WebSocket event thông báo kho đã được trừ
	// websocketManager.Broadcast(...)

	c.JSON(http.StatusOK, gin.H{"message": "Trừ tồn kho thành công"})
}

// CreateReceipt godoc
// @Summary Nhập kho
// @Description Nhập kho sản phẩm
// @Tags Inventory
// @Accept json
// @Produce json
// @Param req body domain.CreateReceiptRequest true "Stock receipt request"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/inventory/receipt [post]
func (h *InventoryHandler) CreateReceipt(c *gin.Context) {
	var req domain.CreateReceiptRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dữ liệu đầu vào không hợp lệ: " + err.Error()})
		return
	}

	userID := "system"
	if uid, exists := c.Get("user_id"); exists {
		userID = uid.(string)
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

	err := h.inventoryService.CreateInventoryReceipt(c.Request.Context(), tx, req, userID)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := tx.Commit().Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi commit transaction: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Nhập kho thành công"})
}
