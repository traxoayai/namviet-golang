package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/core/services"
	"gorm.io/gorm"
)

type PromotionHandler struct {
	db      *gorm.DB
	promoSvc services.PromotionService
}

func NewPromotionHandler(db *gorm.DB, promoSvc services.PromotionService) *PromotionHandler {
	return &PromotionHandler{db: db, promoSvc: promoSvc}
}

// VerifyPromotion godoc
// @Summary Xác thực mã khuyến mãi
// @Description Xác thực và tính toán số tiền được giảm của Voucher
// @Tags Promotions
// @Accept json
// @Produce json
// @Param req body domain.VerifyPromotionRequest true "Verify promotion request payload"
// @Success 200 {object} domain.VerifyPromotionResponse
// @Failure 400 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/promotions/verify [post]
func (h *PromotionHandler) VerifyPromotion(c *gin.Context) {
	var req domain.VerifyPromotionRequest
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

	res, err := h.promoSvc.VerifyVoucher(c.Request.Context(), tx, req)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, res)
}

func (h *PromotionHandler) AutoSuggest(c *gin.Context) {
	promos, err := h.promoSvc.GetAutoSuggestPromotions(c.Request.Context(), h.db)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, promos)
}
