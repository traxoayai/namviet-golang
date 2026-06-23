package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/core/services"
	"gorm.io/gorm"
)

type FinanceHandler struct {
	db          *gorm.DB
	financeSvc  services.FinanceService
}

func NewFinanceHandler(db *gorm.DB, financeSvc services.FinanceService) *FinanceHandler {
	return &FinanceHandler{db: db, financeSvc: financeSvc}
}

// CreateTransaction godoc
// @Summary Tạo giao dịch thu/chi
// @Description Sinh phiếu thu chi, tự động chặn nếu vi phạm luật thuế, chẻ phiếu nếu lệch tiền
// @Tags Finance
// @Accept json
// @Produce json
// @Param req body domain.CreateTransactionRequest true "Create transaction request payload"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/finance/transactions [post]
func (h *FinanceHandler) CreateTransaction(c *gin.Context) {
	var req domain.CreateTransactionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := c.GetString("user_id")

	tx := h.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	err := h.financeSvc.CreateTransaction(c.Request.Context(), tx, req, userID)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, gin.H{"message": "Tạo giao dịch thành công"})
}

// AllocateVATInvoice godoc
// @Summary Phân bổ hóa đơn VAT
// @Description Sử dụng thuật toán Knapsack để gom nhóm các Order Items khớp với tổng giá trị hóa đơn yêu cầu
// @Tags Finance
// @Accept json
// @Produce json
// @Param req body domain.VATAllocationRequest true "VAT allocation request payload"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/finance/vat-allocation [post]
func (h *FinanceHandler) AllocateVATInvoice(c *gin.Context) {
	var req domain.VATAllocationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Read-only logic, no transaction strictly needed, but passed for consistency
	items, err := h.financeSvc.AllocateVATInvoice(c.Request.Context(), h.db, req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var sum float64
	for _, item := range items {
		sum += item.TotalPrice
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Phân bổ thành công",
		"items": items,
		"total_allocated": sum,
	})
}
