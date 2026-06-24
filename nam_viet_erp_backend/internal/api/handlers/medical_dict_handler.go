package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/core/services"
	"gorm.io/gorm"
)

type MedicalDictHandler struct {
	db      *gorm.DB
	service services.MedicalDictService
}

func NewMedicalDictHandler(db *gorm.DB, service services.MedicalDictService) *MedicalDictHandler {
	return &MedicalDictHandler{db: db, service: service}
}

// GetDiseases godoc
// @Summary      Get list of DIC10 diseases
// @Description  Get list of diseases
// @Tags         medical
// @Accept       json
// @Produce      json
// @Success      200  {array}   domain.MedicalDisease
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /medical/diseases [get]
func (h *MedicalDictHandler) GetDiseases(c *gin.Context) {
	tx := h.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	diseases, err := h.service.GetDiseases(c.Request.Context(), tx)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, diseases)
}

// GetPrescriptionTemplate godoc
// @Summary      Get prescription template
// @Description  Get prescription template matching disease and patient age
// @Tags         medical
// @Accept       json
// @Produce      json
// @Param        disease_id query int true "Disease ID"
// @Param        age_months query int true "Age in months"
// @Success      200  {object}  domain.MedicalPrescriptionTemplate
// @Failure      400  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Security     BearerAuth
// @Router       /medical/templates [get]
func (h *MedicalDictHandler) GetPrescriptionTemplate(c *gin.Context) {
	diseaseIDStr := c.Query("disease_id")
	ageMonthsStr := c.Query("age_months")

	diseaseID, err := strconv.ParseInt(diseaseIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid disease_id"})
		return
	}

	ageMonths, err := strconv.Atoi(ageMonthsStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid age_months"})
		return
	}

	tx := h.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	template, err := h.service.GetPrescriptionTemplate(c.Request.Context(), tx, diseaseID, ageMonths)
	if err != nil {
		tx.Rollback()
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "Template not found for this disease and age"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, template)
}

// GetVaccineProtocols godoc
// @Summary      Get vaccine protocols
// @Description  Get list of vaccine protocols
// @Tags         medical
// @Accept       json
// @Produce      json
// @Success      200  {array}   domain.MedicalVaccineProtocol
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /medical/vaccines/protocols [get]
func (h *MedicalDictHandler) GetVaccineProtocols(c *gin.Context) {
	tx := h.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	protocols, err := h.service.GetVaccineProtocols(c.Request.Context(), tx)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, protocols)
}

// CalculateNextDose godoc
// @Summary      Calculate next vaccine dose date
// @Description  Calculate next vaccine dose date based on protocol and last injection
// @Tags         medical
// @Accept       json
// @Produce      json
// @Param        req body domain.VaccineNextDoseRequest true "Calculate Request"
// @Success      200  {object}  domain.VaccineNextDoseResponse
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /medical/vaccines/calculate-next-dose [post]
func (h *MedicalDictHandler) CalculateNextDose(c *gin.Context) {
	var req domain.VaccineNextDoseRequest
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

	res, err := h.service.CalculateNextDoseDate(c.Request.Context(), tx, req)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, res)
}
