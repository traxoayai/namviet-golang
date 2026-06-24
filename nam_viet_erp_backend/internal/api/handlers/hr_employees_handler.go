package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/namvieterp/backend/internal/core/services"
	"gorm.io/gorm"
)

type HREmployeesHandler struct {
	db      *gorm.DB
	service services.HREmployeesService
}

func NewHREmployeesHandler(db *gorm.DB, service services.HREmployeesService) *HREmployeesHandler {
	return &HREmployeesHandler{db: db, service: service}
}

// GetEmployees godoc
// @Summary      Get list of employees
// @Description  Get paginated list of employees
// @Tags         hr
// @Accept       json
// @Produce      json
// @Param        page query int false "Page number"
// @Param        page_size query int false "Page size"
// @Success      200  {object}  map[string]interface{}
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hr/employees [get]
func (h *HREmployeesHandler) GetEmployees(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))

	tx := h.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	employees, total, err := h.service.GetEmployees(c.Request.Context(), tx, page, pageSize)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, gin.H{
		"data":  employees,
		"total": total,
		"page":  page,
	})
}

// GetEmployeeProfile godoc
// @Summary      Get employee profile
// @Description  Get employee profile with contracts and payrolls
// @Tags         hr
// @Accept       json
// @Produce      json
// @Param        id path string true "Employee ID"
// @Success      200  {object}  domain.EmployeeProfileDTO
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hr/employees/{id} [get]
func (h *HREmployeesHandler) GetEmployeeProfile(c *gin.Context) {
	targetID := c.Param("id")

	tx := h.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	profile, err := h.service.GetEmployeeProfile(c.Request.Context(), tx, targetID)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, profile)
}
