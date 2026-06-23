package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/namvieterp/backend/internal/core/services"
	"github.com/namvieterp/backend/internal/workers"
)

type GdtHandler struct {
	gdtService *services.GdtService
	gdtWorker  *workers.GdtWorker
}

func NewGdtHandler(gdtService *services.GdtService, gdtWorker *workers.GdtWorker) *GdtHandler {
	return &GdtHandler{
		gdtService: gdtService,
		gdtWorker:  gdtWorker,
	}
}

func (h *GdtHandler) UpdateGdtToken(c *gin.Context) {
	var payload struct {
		Token string `json:"token" binding:"required"`
	}
	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid token payload"})
		return
	}

	if err := h.gdtService.UpdateToken(payload.Token); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Token updated successfully"})
}

func (h *GdtHandler) GetGdtStatus(c *gin.Context) {
	status, err := h.gdtService.GetTokenStatus()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, status)
}

func (h *GdtHandler) SyncGdtNow(c *gin.Context) {
	// Trigger the worker's sync routine asynchronously so we don't block the HTTP request
	go h.gdtWorker.SyncRoutine()
	
	c.JSON(http.StatusOK, gin.H{"message": "Sync started in background"})
}
