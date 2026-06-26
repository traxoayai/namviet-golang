package main

import (
	"context"
	"log"
	"os"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/namvieterp/backend/internal/api/handlers"
	"github.com/namvieterp/backend/internal/api/routes"
	"github.com/namvieterp/backend/internal/core/services"
	"github.com/namvieterp/backend/internal/repository/postgres"
	"github.com/namvieterp/backend/internal/workers"
)

func main() {
	// Load .env if present
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, relying on OS env vars")
	}

	// Initialize Database
	db, err := postgres.InitDB()
	if err != nil {
		log.Fatalf("Could not connect to database: %v", err)
	}

	r := gin.Default()

	// CORS Configuration
	config := cors.DefaultConfig()
	config.AllowOrigins = []string{"*"}
	config.AllowMethods = []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"}
	config.AllowHeaders = []string{"Origin", "Content-Length", "Content-Type", "Authorization", "apikey"}
	r.Use(cors.New(config))

	// Setup services & handlers
	gdtService := services.NewGdtService(db)
	invoiceService := services.NewInvoiceService(db)
	gdtWorker := workers.NewGdtWorker(db, gdtService, invoiceService)
	gdtWorker.Start()

	invRepo := postgres.NewInventoryRepository()
	invSvc := services.NewInventoryService(invRepo)
	invHandler := handlers.NewInventoryHandler(db, invSvc)

	orderRepo := postgres.NewOrderRepository()
	financeRepo := postgres.NewFinanceRepository()
	financeSvc := services.NewFinanceService(financeRepo)
	financeHandler := handlers.NewFinanceHandler(db, financeSvc)

	promoRepo := postgres.NewPromotionRepository()
	promoSvc := services.NewPromotionService(promoRepo)
	promoHandler := handlers.NewPromotionHandler(db, promoSvc)

	orderSvc := services.NewOrderService(orderRepo, invSvc, financeSvc, promoSvc)
	orderHandler := handlers.NewOrderHandler(db, orderSvc)

	crmRepo := postgres.NewCRMRepository()
	crmSvc := services.NewCRMService(crmRepo)
	crmHandler := handlers.NewCRMHandler(db, crmSvc)

	wsHandler := handlers.NewWsHandler()
	pgListener := workers.NewPgListener(wsHandler)
	if pgListener != nil {
		pgListener.Start()
	}

	clinicRepo := postgres.NewClinicRepository()
	clinicSvc := services.NewClinicService(clinicRepo)
	clinicHandler := handlers.NewClinicHandler(db, clinicSvc)

	purchRepo := postgres.NewPurchasingRepository()
	purchSvc := services.NewPurchasingService(purchRepo)
	purchHandler := handlers.NewPurchasingHandler(db, purchSvc)

	logisRepo := postgres.NewLogisticsRepository()
	logisSvc := services.NewLogisticsService(logisRepo, crmSvc)
	logisHandler := handlers.NewLogisticsHandler(db, logisSvc)

	aiHandler := handlers.NewAIHandler()

	hrEmpRepo := postgres.NewHREmployeesRepository()
	hrEmpSvc := services.NewHREmployeesService(hrEmpRepo)
	hrEmpHandler := handlers.NewHREmployeesHandler(db, hrEmpSvc)

	hrShiftRepo := postgres.NewHRWorkShiftsRepository()
	hrAttRepo := postgres.NewHRAttendancesRepository()
	hrShiftSvc := services.NewHRWorkShiftsService(hrShiftRepo, hrAttRepo)
	hrShiftHandler := handlers.NewHRWorkShiftsHandler(db, hrShiftSvc)

	hrPayrollRepo := postgres.NewHRPayrollsRepository()
	hrPayrollSvc := services.NewHRPayrollsService(hrPayrollRepo)
	hrPayrollHandler := handlers.NewHRPayrollsHandler(db, hrPayrollSvc)

	medDictRepo := postgres.NewMedicalDictRepository()
	medDictSvc := services.NewMedicalDictService(medDictRepo)
	medDictHandler := handlers.NewMedicalDictHandler(db, medDictSvc)

	jobRepo := postgres.NewJobRepository()
	mktRepo := postgres.NewMarketingRepository()
	mktSvc := services.NewMarketingService(mktRepo, jobRepo)
	mktHandler := handlers.NewMarketingHandler(db, mktSvc)

	// Start Marketing Worker
	mktWorker := workers.NewMarketingWorker(db, jobRepo, mktRepo)
	go mktWorker.Start(context.Background())

	hrKpiRepo := postgres.NewHRKPIRepository(db)
	hrKpiSvc := services.NewHRKPIService(hrKpiRepo)
	hrKpiHandler := handlers.NewHRKPIHandler(hrKpiSvc, db)

	// Setup Routes
	routes.SetupRoutes(r, db, gdtWorker, gdtService, invHandler, orderHandler, financeHandler, crmHandler, clinicHandler, wsHandler, promoHandler, purchHandler, logisHandler, aiHandler, hrEmpHandler, hrShiftHandler, hrPayrollHandler, medDictHandler, mktHandler, hrKpiHandler)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server running on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}
}
