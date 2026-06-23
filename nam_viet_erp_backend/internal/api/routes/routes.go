package routes

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/namvieterp/backend/internal/api/handlers"
	"github.com/namvieterp/backend/internal/api/middleware"
	"github.com/namvieterp/backend/internal/core/services"
	"github.com/namvieterp/backend/internal/workers"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	"gorm.io/gorm"
)

func SetupRoutes(
	r *gin.Engine,
	db *gorm.DB,
	gdtWorker *workers.GdtWorker,
	gdtService *services.GdtService,
	inventoryHandler *handlers.InventoryHandler,
	orderHandler *handlers.OrderHandler,
	financeHandler *handlers.FinanceHandler,
	crmHandler *handlers.CRMHandler,
	clinicHandler *handlers.ClinicHandler,
	wsHandler *handlers.WsHandler,
	promotionHandler *handlers.PromotionHandler,
	purchasingHandler *handlers.PurchasingHandler,
	logisticsHandler *handlers.LogisticsHandler,
	aiHandler *handlers.AIHandler,
) {
	gdtHandler := handlers.NewGdtHandler(gdtService, gdtWorker)

	// WebSockets (No Auth for now or handle via query params in production)
	ws := r.Group("/ws/v1")
	{
		ws.GET("/clinic/queue", wsHandler.QueueUpdates)
	}

	// Swagger
	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	v1 := r.Group("/api/v1")
	{
		// Inventory
		inventory := v1.Group("/inventory")
		inventory.Use(middleware.SupabaseAuthMiddleware())
		{
			inventory.POST("/validate", inventoryHandler.ValidateStock)
			inventory.POST("/deduct", inventoryHandler.DeductStock)
			inventory.POST("/receipt", inventoryHandler.CreateReceipt)
		}

		// Orders
		orders := v1.Group("/orders")
		orders.Use(middleware.SupabaseAuthMiddleware())
		{
			orders.POST("", orderHandler.CreateSalesOrder)
		}

		// Finance
		finance := v1.Group("/finance")
		finance.Use(middleware.SupabaseAuthMiddleware())
		{
			finance.POST("/transactions", financeHandler.CreateTransaction)
			finance.POST("/vat-allocation", financeHandler.AllocateVATInvoice)
		}

		// CRM
		crm := v1.Group("/crm")
		crm.Use(middleware.SupabaseAuthMiddleware())
		{
			crm.POST("/loyalty/earn", crmHandler.EarnLoyaltyPoints)
		}

		// Clinic
		clinic := v1.Group("/clinic")
		clinic.Use(middleware.SupabaseAuthMiddleware())
		{
			clinic.POST("/appointments", clinicHandler.BookAppointment)
			clinic.POST("/appointments/:id/check-in", clinicHandler.CheckInPatient)
		}

		// Promotions
		promotions := v1.Group("/promotions")
		promotions.Use(middleware.SupabaseAuthMiddleware())
		{
			promotions.POST("/verify", promotionHandler.VerifyPromotion)
		}

		// Purchasing
		purchasing := v1.Group("/purchasing")
		purchasing.Use(middleware.SupabaseAuthMiddleware())
		{
			purchasing.POST("/orders", purchasingHandler.CreatePurchaseOrder)
		}

		// Logistics
		logistics := v1.Group("/logistics")
		logistics.Use(middleware.SupabaseAuthMiddleware())
		{
			logistics.POST("/orders/:id/shipping", logisticsHandler.CreateShippingOrder)
		}

		// AI Chat - with RateLimit and RBAC (Admin, Pharmacist, Doctor)
		ai := v1.Group("/ai")
		ai.Use(middleware.SupabaseAuthMiddleware())
		ai.Use(middleware.RateLimit(20, time.Hour))
		ai.Use(middleware.RequireRole("admin", "pharmacist", "doctor"))
		{
			ai.POST("/chat", aiHandler.HandleChat)
		}

		// Webhooks
		webhooks := v1.Group("/webhooks")
		{
			webhooks.POST("/logistics/status-update", logisticsHandler.HandleGHNWebhook)
		}

		// GDT webhook/token routes (No auth required for extension simplicity)
		v1.POST("/finance/invoices/gdt-token", gdtHandler.UpdateGdtToken)
		v1.GET("/finance/invoices/gdt-status", gdtHandler.GetGdtStatus)
	}
}
