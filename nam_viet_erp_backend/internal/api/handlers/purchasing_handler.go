package handlers

import (
	"net/http"
	"strconv"

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

// GetPurchaseOrder godoc
// @Summary      Get purchase order details
// @Description  Get purchase order details including enriched item data like total_stock and avg_monthly_sold
// @Tags         purchasing
// @Accept       json
// @Produce      json
// @Param        id   path      int  true  "Purchase Order ID"
// @Success      200  {object}  domain.PurchaseOrderDetailDTO
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /purchasing/orders/{id} [get]
func (h *PurchasingHandler) GetPurchaseOrder(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID không hợp lệ"})
		return
	}

	tx := h.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	res, err := h.purchSvc.GetPurchaseOrder(c.Request.Context(), tx, id)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if err := tx.Commit().Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi hệ thống khi commit transaction"})
		return
	}

	c.JSON(http.StatusOK, res)
}
