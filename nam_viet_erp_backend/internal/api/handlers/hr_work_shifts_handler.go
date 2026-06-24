package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/core/services"
	"gorm.io/gorm"
)

type HRWorkShiftsHandler struct {
	db      *gorm.DB
	service services.HRWorkShiftsService
}

func NewHRWorkShiftsHandler(db *gorm.DB, service services.HRWorkShiftsService) *HRWorkShiftsHandler {
	return &HRWorkShiftsHandler{db: db, service: service}
}

// RegisterShift godoc
// @Summary      Register work shift
// @Description  Register a new work shift for an employee
// @Tags         hr
// @Accept       json
// @Produce      json
// @Param        req body domain.ShiftRegisterRequest true "Shift Request"
// @Success      200  {object}  domain.HRWorkShift
// @Failure      400  {object}  map[string]string
// @Failure      409  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hr/shifts/register [post]
func (h *HRWorkShiftsHandler) RegisterShift(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var req domain.ShiftRegisterRequest
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

	shift, err := h.service.RegisterShift(c.Request.Context(), tx, userID.(string), req)
	if err != nil {
		tx.Rollback()
		if err.Error() == "Khung giờ này đã bị trùng lặp với ca đã đăng ký!" {
			c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, shift)
}

// CheckIn godoc
// @Summary      Check-in to a shift
// @Description  Check-in to a shift with geolocation
// @Tags         hr
// @Accept       json
// @Produce      json
// @Param        req body domain.HRCheckInRequest true "CheckIn Request"
// @Success      200  {object}  domain.HRCheckInResponse
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hr/shifts/check-in [post]
func (h *HRWorkShiftsHandler) CheckIn(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var req domain.HRCheckInRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	clientIP := c.ClientIP()

	tx := h.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	res, err := h.service.CheckIn(c.Request.Context(), tx, userID.(string), clientIP, req)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, res)
}
