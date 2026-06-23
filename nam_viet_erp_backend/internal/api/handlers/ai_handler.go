package handlers

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
)

type AIHandler struct{}

func NewAIHandler() *AIHandler {
	return &AIHandler{}
}

type AIChatRequest struct {
	Message string `json:"message" binding:"required"`
}

// HandleChat godoc
// @Summary AI Chatbot Streaming
// @Description Gửi câu hỏi cho AI và nhận câu trả lời dạng Server-Sent Events (SSE)
// @Tags System
// @Accept json
// @Produce text/event-stream
// @Param req body handlers.AIChatRequest true "Chat request"
// @Success 200 {string} string "SSE Stream"
// @Router /api/v1/ai/chat [post]
func (h *AIHandler) HandleChat(c *gin.Context) {
	var req AIChatRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	apiKey := os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "GEMINI_API_KEY is not configured"})
		return
	}

	// Prepare Gemini Request
	// Using Gemini Pro API for streamGenerateContent
	url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:streamGenerateContent?key=%s", apiKey)

	systemContext := "Bạn là trợ lý Y Tế & Quản trị Hệ thống ERP Nam Việt. Hãy tư vấn ngắn gọn, chuyên nghiệp."
	fullPrompt := systemContext + "\n\nUser: " + req.Message

	payload := map[string]interface{}{
		"contents": []map[string]interface{}{
			{
				"parts": []map[string]interface{}{
					{"text": fullPrompt},
				},
			},
		},
	}

	payloadBytes, _ := json.Marshal(payload)

	httpReq, err := http.NewRequestWithContext(c.Request.Context(), "POST", url, bytes.NewBuffer(payloadBytes))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi tạo request nội bộ"})
		return
	}
	httpReq.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(httpReq)
	if err != nil {
		c.JSON(http.StatusBadGateway, gin.H{"error": "Lỗi kết nối tới Gemini API"})
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		c.JSON(resp.StatusCode, gin.H{"error": "Gemini API Error: " + string(bodyBytes)})
		return
	}

	// Set headers for SSE
	c.Writer.Header().Set("Content-Type", "text/event-stream")
	c.Writer.Header().Set("Cache-Control", "no-cache")
	c.Writer.Header().Set("Connection", "keep-alive")
	c.Writer.Header().Set("Transfer-Encoding", "chunked")

	reader := bufio.NewReader(resp.Body)
	for {
		line, err := reader.ReadBytes('\n')
		if err != nil {
			if err == io.EOF {
				break
			}
			return
		}

		// Gemini stream returns JSON array chunks or SSE-like format depending on the exact endpoint used.
		// For REST streamGenerateContent, it returns an array of JSON objects.
		// We'll just stream the raw bytes back to the client as an SSE event for simplicity,
		// or parse and stream the text.
		
		// To make it simple SSE:
		strLine := strings.TrimSpace(string(line))
		if strLine != "" && strLine != "[" && strLine != "]" && strLine != "," {
			// Write as SSE
			fmt.Fprintf(c.Writer, "data: %s\n\n", strLine)
			c.Writer.Flush()
		}
	}
	
	fmt.Fprintf(c.Writer, "event: end\ndata: [DONE]\n\n")
	c.Writer.Flush()
}
