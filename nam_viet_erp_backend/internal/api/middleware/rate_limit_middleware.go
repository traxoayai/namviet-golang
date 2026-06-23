package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

type clientStats struct {
	count     int
	lastReset time.Time
}

var (
	clients = make(map[string]*clientStats)
	mu      sync.Mutex
)

// RateLimit is a simple in-memory rate limiter based on IP or User ID
func RateLimit(limit int, window time.Duration) gin.HandlerFunc {
	return func(c *gin.Context) {
		clientIP := c.ClientIP()

		mu.Lock()
		stats, exists := clients[clientIP]
		if !exists {
			stats = &clientStats{
				count:     0,
				lastReset: time.Now(),
			}
			clients[clientIP] = stats
		}

		if time.Since(stats.lastReset) > window {
			stats.count = 0
			stats.lastReset = time.Now()
		}

		stats.count++
		currentCount := stats.count
		mu.Unlock()

		if currentCount > limit {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error": "Rate limit exceeded. Please try again later.",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}
