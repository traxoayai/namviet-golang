package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/core/services"
	"gorm.io/gorm"
)

type MarketingHandler struct {
	db      *gorm.DB
	service services.MarketingService
}

func NewMarketingHandler(db *gorm.DB, service services.MarketingService) *MarketingHandler {
	return &MarketingHandler{db: db, service: service}
}

// CreateCampaign godoc
// @Summary      Create Campaign
// @Description  Create a new marketing campaign with drag-drop node configs
// @Tags         marketing
// @Accept       json
// @Produce      json
// @Param        req body domain.MarketingCampaign true "Campaign Config"
// @Success      200  {object}  domain.MarketingCampaign
// @Failure      400  {object}  map[string]string
// @Security     BearerAuth
// @Router       /marketing/campaigns [post]
func (h *MarketingHandler) CreateCampaign(c *gin.Context) {
	var req domain.MarketingCampaign
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

	req.Status = "draft"
	if err := h.service.CreateCampaign(c.Request.Context(), tx, &req); err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, req)
}

// StartCampaign godoc
// @Summary      Start Campaign
// @Description  Start campaign and enqueue marketing jobs
// @Tags         marketing
// @Produce      json
// @Param        id path int true "Campaign ID"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Security     BearerAuth
// @Router       /marketing/campaigns/{id}/start [post]
func (h *MarketingHandler) StartCampaign(c *gin.Context) {
	idStr := c.Param("id")
	campaignID, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid id"})
		return
	}

	tx := h.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	if err := h.service.StartCampaign(c.Request.Context(), tx, campaignID); err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, gin.H{"message": "Campaign started and jobs enqueued"})
}

// GetMetrics godoc
// @Summary      Get Campaign Metrics
// @Description  Get funnel metrics for ECharts
// @Tags         marketing
// @Produce      json
// @Param        id path int true "Campaign ID"
// @Success      200  {object}  domain.MarketingCampaignMetric
// @Failure      400  {object}  map[string]string
// @Security     BearerAuth
// @Router       /marketing/campaigns/{id}/metrics [get]
func (h *MarketingHandler) GetMetrics(c *gin.Context) {
	idStr := c.Param("id")
	campaignID, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid id"})
		return
	}

	tx := h.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	metrics, err := h.service.GetMetrics(c.Request.Context(), tx, campaignID)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, metrics)
}

// CreateSurvey godoc
// @Summary      Create Survey
// @Description  Create a survey with Form Builder
// @Tags         marketing
// @Accept       json
// @Produce      json
// @Param        req body domain.MarketingSurvey true "Survey Config"
// @Success      200  {object}  domain.MarketingSurvey
// @Failure      400  {object}  map[string]string
// @Security     BearerAuth
// @Router       /marketing/surveys [post]
func (h *MarketingHandler) CreateSurvey(c *gin.Context) {
	var req domain.MarketingSurvey
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

	if err := h.service.CreateSurvey(c.Request.Context(), tx, &req); err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, req)
}

// GetSurveys godoc
// @Summary      Get Surveys
// @Description  Get list of surveys
// @Tags         marketing
// @Produce      json
// @Success      200  {array}   domain.MarketingSurvey
// @Failure      500  {object}  map[string]string
// @Security     BearerAuth
// @Router       /marketing/surveys [get]
func (h *MarketingHandler) GetSurveys(c *gin.Context) {
	tx := h.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	surveys, err := h.service.GetSurveys(c.Request.Context(), tx)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusOK, surveys)
}
