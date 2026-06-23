package middleware

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// RequireRole checks if the user has one of the required roles in their JWT token.
// Note: In a real app, you would parse the JWT token properly using a JWT library.
// For simplicity in this handover, we parse from a mock "app_metadata" header or assume it's set in context by an AuthMiddleware.
func RequireRole(roles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Mock: In a real Supabase setup, you decode the JWT Bearer token and read `app_metadata.roles`
		// Here we read from a custom header 'X-User-Roles' for demonstration, or you can implement actual JWT parsing.
		userRolesStr := c.GetHeader("X-User-Roles")
		if userRolesStr == "" {
			// Try to get from Gin Context if an upstream Auth middleware set it
			if val, exists := c.Get("user_roles"); exists {
				userRolesStr = val.(string)
			}
		}

		if userRolesStr == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized: Missing roles"})
			c.Abort()
			return
		}

		var userRoles []string
		if err := json.Unmarshal([]byte(userRolesStr), &userRoles); err != nil {
			// Fallback: assume comma separated
			userRoles = strings.Split(userRolesStr, ",")
		}

		hasRole := false
		for _, requiredRole := range roles {
			for _, userRole := range userRoles {
				if strings.TrimSpace(userRole) == requiredRole {
					hasRole = true
					break
				}
			}
			if hasRole {
				break
			}
		}

		if !hasRole {
			c.JSON(http.StatusForbidden, gin.H{"error": "Forbidden: You do not have the required role"})
			c.Abort()
			return
		}

		c.Next()
	}
}
