package handlers

import (
	"log"
	"net/http"
	"sync"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // allow all for simplicity, restrict in production
	},
}

type WsHandler struct {
	// A map of connected clients
	clients map[*websocket.Conn]bool
	mu      sync.Mutex
}

func NewWsHandler() *WsHandler {
	return &WsHandler{
		clients: make(map[*websocket.Conn]bool),
	}
}

// QueueUpdates godoc
// @Summary WebSocket cho hàng đợi
// @Description Kết nối WebSocket để nhận realtime updates từ queue
// @Tags Clinic
// @Router /ws/v1/clinic/queue [get]
func (h *WsHandler) QueueUpdates(c *gin.Context) {
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Println("Failed to set websocket upgrade:", err)
		return
	}

	h.mu.Lock()
	h.clients[conn] = true
	h.mu.Unlock()

	defer func() {
		h.mu.Lock()
		delete(h.clients, conn)
		h.mu.Unlock()
		conn.Close()
	}()

	// Keep connection alive and read messages (mostly ping/pong)
	for {
		_, _, err := conn.ReadMessage()
		if err != nil {
			break
		}
	}
}

func (h *WsHandler) Broadcast(message []byte) {
	h.mu.Lock()
	defer h.mu.Unlock()
	for client := range h.clients {
		if err := client.WriteMessage(websocket.TextMessage, message); err != nil {
			log.Println("WS Broadcast error:", err)
			client.Close()
			delete(h.clients, client)
		}
	}
}
