package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/core/services"
	"gorm.io/gorm"
)

type ClinicHandler struct {
	db        *gorm.DB
	clinicSvc services.ClinicService
}

func NewClinicHandler(db *gorm.DB, clinicSvc services.ClinicService) *ClinicHandler {
	return &ClinicHandler{db: db, clinicSvc: clinicSvc}
}

// BookAppointment godoc
// @Summary Đặt lịch khám
// @Description Lễ tân tạo lịch hẹn khám bệnh cho bệnh nhân
// @Tags Clinic
// @Accept json
// @Produce json
// @Param req body domain.BookAppointmentRequest true "Book appointment request payload"
// @Success 200 {object} domain.Appointment
// @Failure 400 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/clinic/appointments [post]
func (h *ClinicHandler) BookAppointment(c *gin.Context) {
	var req domain.BookAppointmentRequest
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

	apt, err := h.clinicSvc.BookAppointment(c.Request.Context(), tx, req)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, apt)
}

// CheckInPatient godoc
// @Summary Bệnh nhân Check-in
// @Description Lễ tân xác nhận bệnh nhân đã tới và đưa vào hàng đợi chờ khám
// @Tags Clinic
// @Accept json
// @Produce json
// @Param id path string true "Appointment ID"
// @Param req body domain.CheckInRequest false "Check-in request payload"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/clinic/appointments/{id}/check-in [post]
func (h *ClinicHandler) CheckInPatient(c *gin.Context) {
	aptID := c.Param("id")

	tx := h.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	err := h.clinicSvc.CheckInPatient(c.Request.Context(), tx, aptID)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, gin.H{"message": "Check-in thành công"})
}
