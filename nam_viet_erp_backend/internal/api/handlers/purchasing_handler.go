package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/core/services"
	"gorm.io/gorm"
)

type PurchasingHandler struct {
	db      *gorm.DB
	purchSvc services.PurchasingService
}

func NewPurchasingHandler(db *gorm.DB, purchSvc services.PurchasingService) *PurchasingHandler {
	return &PurchasingHandler{db: db, purchSvc: purchSvc}
}

// CreatePurchaseOrder godoc
// @Summary Tạo đơn đặt hàng PO
// @Description Tạo đơn hàng từ nhà cung cấp
// @Tags Purchasing
// @Accept json
// @Produce json
// @Param req body domain.CreatePurchaseOrderRequest true "Create PO request"
// @Success 200 {object} domain.PurchaseOrder
// @Failure 400 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/purchasing/orders [post]
func (h *PurchasingHandler) CreatePurchaseOrder(c *gin.Context) {
	var req domain.CreatePurchaseOrderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tx := h.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	po, err := h.purchSvc.CreatePurchaseOrder(c.Request.Context(), tx, req)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, po)
}

// AutoReplenishMinMax godoc
// @Summary Tạo dự trù mua hàng hàng loạt theo mức Min-Max
// @Description Quét kho và tự động đẻ các đơn đặt hàng nháp cho sản phẩm thiếu hụt
// @Tags Purchasing
// @Accept json
// @Produce json
// @Success 200 {object} domain.AutoReplenishResponse
// @Failure 400 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/purchasing/auto-replenish-min-max [post]
func (h *PurchasingHandler) AutoReplenishMinMax(c *gin.Context) {
	// Giả sử request chỉ có warehouse_id, mặc định là B2B warehouse (id=1)
	warehouseID := int64(1) // Trong thực tế lấy từ query hoặc body

	// Giả sử lấy user_id từ JWT
	userID := "system-auto"
	if uid, exists := c.Get("user_id"); exists {
		userID = uid.(string)
	}

	tx := h.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	res, err := h.purchSvc.AutoReplenishMinMax(c.Request.Context(), tx, warehouseID, userID)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, res)
}
