package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/core/services"
	"gorm.io/gorm"
)

type HRPayrollsHandler struct {
	db      *gorm.DB
	service services.HRPayrollsService
}

func NewHRPayrollsHandler(db *gorm.DB, service services.HRPayrollsService) *HRPayrollsHandler {
	return &HRPayrollsHandler{db: db, service: service}
}

type UserRoleInfo struct {
	RoleName string
	BranchID int64
}

// CalculatePayroll godoc
// @Summary      Calculate payroll
// @Description  Calculate payroll for an employee
// @Tags         hr
// @Accept       json
// @Produce      json
// @Param        id path string true "Employee ID"
// @Param        req body domain.PayrollCalculateRequest true "Calculate Request"
// @Success      200  {object}  domain.HRPayroll
// @Failure      400  {object}  map[string]string
// @Failure      403  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /hr/employees/{id}/payroll/calculate [post]
func (h *HRPayrollsHandler) CalculatePayroll(c *gin.Context) {
	currentUserID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	targetUserID := c.Param("id")

	var req domain.PayrollCalculateRequest
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

	// Authorization Check (TC_10.2)
	allowed, err := h.checkPayrollAuthorization(tx, currentUserID.(string), targetUserID)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error checking authorization"})
		return
	}

	if !allowed {
		tx.Rollback()
		c.JSON(http.StatusForbidden, gin.H{"error": "403 Forbidden: You do not have permission to view or calculate this payroll"})
		return
	}

	payroll, err := h.service.CalculatePayroll(c.Request.Context(), tx, targetUserID, req)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, payroll)
}

func (h *HRPayrollsHandler) checkPayrollAuthorization(tx *gorm.DB, currentUserID, targetUserID string) (bool, error) {
	if currentUserID == targetUserID {
		return true, nil // Employee can view their own
	}

	// Fetch requester's roles
	var currentRoles []UserRoleInfo
	err := tx.Table("user_roles").
		Select("roles.name as role_name, user_roles.branch_id").
		Joins("JOIN roles ON roles.id = user_roles.role_id").
		Where("user_roles.user_id = ?", currentUserID).
		Find(&currentRoles).Error
	if err != nil {
		return false, err
	}

	isAdminOrHR := false
	var currentBranchIDs []int64

	for _, r := range currentRoles {
		if r.RoleName == "Admin" || r.RoleName == "HR_Manager" {
			isAdminOrHR = true
			break
		}
		if r.RoleName == "Branch_Manager" {
			currentBranchIDs = append(currentBranchIDs, r.BranchID)
		}
	}

	if isAdminOrHR {
		return true, nil
	}

	if len(currentBranchIDs) > 0 {
		// Fetch target user's branches
		var targetRoles []UserRoleInfo
		err := tx.Table("user_roles").
			Select("roles.name as role_name, user_roles.branch_id").
			Joins("JOIN roles ON roles.id = user_roles.role_id").
			Where("user_roles.user_id = ?", targetUserID).
			Find(&targetRoles).Error
		if err != nil {
			return false, err
		}

		// If they share any branch, it's allowed
		for _, tb := range targetRoles {
			for _, cb := range currentBranchIDs {
				if tb.BranchID == cb {
					return true, nil
				}
			}
		}
	}

	return false, nil // Default deny
}
