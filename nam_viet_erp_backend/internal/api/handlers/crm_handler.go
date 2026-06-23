package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/core/services"
	"gorm.io/gorm"
)

type CRMHandler struct {
	db      *gorm.DB
	crmSvc  services.CRMService
}

func NewCRMHandler(db *gorm.DB, crmSvc services.CRMService) *CRMHandler {
	return &CRMHandler{db: db, crmSvc: crmSvc}
}

// EarnLoyaltyPoints godoc
// @Summary Tích điểm thành viên
// @Description Cộng điểm cho khách hàng dựa trên giá trị đơn hàng
// @Tags CRM
// @Accept json
// @Produce json
// @Param req body domain.EarnLoyaltyRequest true "Earn loyalty request payload"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/crm/loyalty/earn [post]
func (h *CRMHandler) EarnLoyaltyPoints(c *gin.Context) {
	var req domain.EarnLoyaltyRequest
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

	err := h.crmSvc.EarnLoyaltyPoints(c.Request.Context(), tx, req)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, gin.H{"message": "Tích điểm thành công"})
}
