package handlers

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/core/services"
	"gorm.io/gorm"
)

type HRKPIHandler struct {
	service services.HRKPIService
	db      *gorm.DB
}

func NewHRKPIHandler(service services.HRKPIService, db *gorm.DB) *HRKPIHandler {
	return &HRKPIHandler{
		service: service,
		db:      db,
	}
}

// AssignKPI godoc
// @Summary Assign KPI Target
// @Description Assign a KPI target to an employee
// @Tags HR KPI
// @Accept json
// @Produce json
// @Param request body domain.AssignKPITargetRequest true "KPI Target Info"
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/hr/kpi-targets [post]
func (h *HRKPIHandler) AssignKPI(c *gin.Context) {
	var req domain.AssignKPITargetRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Lấy current user id từ context (được JWT Middleware set vào)
	currentUserID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	// Bắt đầu transaction
	tx := h.db.Begin()
	if tx.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to start transaction"})
		return
	}

	target, err := h.service.AssignKPITarget(c.Request.Context(), tx, currentUserID.(string), req)
	if err != nil {
		tx.Rollback()
		if err.Error() == "forbidden: you do not have permission to assign KPI to this employee" {
			c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		}
		return
	}

	if err := tx.Commit().Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to commit transaction"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "KPI assigned successfully",
		"data":    target,
	})
}

// GetMyKPIProgress godoc
// @Summary Get My KPI Progress
// @Description View personal KPI progress for a specific month and year
// @Tags HR KPI
// @Accept json
// @Produce json
// @Param month query int true "Month"
// @Param year query int true "Year"
// @Success 200 {object} domain.KPIProgressResponse
// @Router /api/v1/hr/kpi-progress/me [get]
func (h *HRKPIHandler) GetMyKPIProgress(c *gin.Context) {
	// Lấy current user id từ context
	currentUserID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	// Lấy param month và year
	monthStr := c.Query("month")
	yearStr := c.Query("year")
	if monthStr == "" || yearStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "month and year are required"})
		return
	}
	
	// Convert sang int (sử dụng strconv, ở đây lấy gọn do code nhỏ)
	var month, year int
	_, errMonth := fmt.Sscanf(monthStr, "%d", &month)
	_, errYear := fmt.Sscanf(yearStr, "%d", &year)
	
	if errMonth != nil || errYear != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid month or year format"})
		return
	}

	tx := h.db.Begin()
	if tx.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to start transaction"})
		return
	}

	resp, err := h.service.GetMyKPIProgress(c.Request.Context(), tx, currentUserID.(string), month, year)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if err := tx.Commit().Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to commit transaction"})
		return
	}

	c.JSON(http.StatusOK, resp)
}

// GetAllMetrics godoc
// @Summary Get All KPI Metrics
// @Description Fetch all available KPI metrics
// @Tags HR KPI
// @Accept json
// @Produce json
// @Success 200 {array} domain.HRKPIMetric
// @Router /api/v1/hr/kpi-metrics [get]
func (h *HRKPIHandler) GetAllMetrics(c *gin.Context) {
	metrics, err := h.service.GetAllMetrics(c.Request.Context(), h.db)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch metrics: " + err.Error()})
		return
	}
	c.JSON(http.StatusOK, metrics)
}
