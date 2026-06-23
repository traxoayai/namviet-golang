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
