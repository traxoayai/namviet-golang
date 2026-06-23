package handlers

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/gin-gonic/gin"
	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/stretchr/testify/assert"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// MockInventoryService implements services.InventoryService
type MockInventoryService struct {
	ValidateStockFunc  func(ctx context.Context, tx *gorm.DB, req domain.ValidateStockRequest) error
	DeductStockFunc    func(ctx context.Context, tx *gorm.DB, req domain.DeductStockRequest, userID string) error
	CreateReceiptFunc  func(ctx context.Context, tx *gorm.DB, req domain.CreateReceiptRequest, userID string) error
}

func (m *MockInventoryService) ValidateStockAvailability(ctx context.Context, tx *gorm.DB, req domain.ValidateStockRequest) error {
	if m.ValidateStockFunc != nil {
		return m.ValidateStockFunc(ctx, tx, req)
	}
	return nil
}

func (m *MockInventoryService) DeductStockFEFO(ctx context.Context, tx *gorm.DB, req domain.DeductStockRequest, userID string) error {
	if m.DeductStockFunc != nil {
		return m.DeductStockFunc(ctx, tx, req, userID)
	}
	return nil
}

func (m *MockInventoryService) CreateInventoryReceipt(ctx context.Context, tx *gorm.DB, req domain.CreateReceiptRequest, userID string) error {
	if m.CreateReceiptFunc != nil {
		return m.CreateReceiptFunc(ctx, tx, req, userID)
	}
	return nil
}

func setupTestRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	return gin.Default()
}

func setupMockDB(t *testing.T) (*gorm.DB, sqlmock.Sqlmock) {
	sqlDB, mock, err := sqlmock.New()
	assert.NoError(t, err)

	dialector := postgres.New(postgres.Config{
		Conn:       sqlDB,
		DriverName: "postgres",
	})
	db, err := gorm.Open(dialector, &gorm.Config{
		SkipDefaultTransaction: true,
	})
	assert.NoError(t, err)
	return db, mock
}

func TestValidateStock_Success(t *testing.T) {
	mockSvc := &MockInventoryService{
		ValidateStockFunc: func(ctx context.Context, tx *gorm.DB, req domain.ValidateStockRequest) error {
			return nil
		},
	}
	
	handler := NewInventoryHandler(nil, mockSvc)

	router := setupTestRouter()
	router.POST("/validate", handler.ValidateStock)

	reqPayload := domain.ValidateStockRequest{
		WarehouseID: 1,
		Items: []domain.ValidateStockItem{
			{ProductID: 10, Quantity: 5, Uom: "Hộp"},
		},
	}
	body, _ := json.Marshal(reqPayload)

	req, _ := http.NewRequest("POST", "/validate", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "Tồn kho hợp lệ", response["message"])
}

func TestValidateStock_InvalidInput(t *testing.T) {
	mockSvc := &MockInventoryService{}
	handler := NewInventoryHandler(nil, mockSvc)

	router := setupTestRouter()
	router.POST("/validate", handler.ValidateStock)

	// Missing WarehouseID
	reqPayload := map[string]interface{}{
		"items": []map[string]interface{}{
			{"product_id": 10, "quantity": 5, "uom": "Hộp"},
		},
	}
	body, _ := json.Marshal(reqPayload)

	req, _ := http.NewRequest("POST", "/validate", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestDeductStock_Success(t *testing.T) {
	db, mock := setupMockDB(t)
	// Expect Begin transaction
	mock.ExpectBegin()
	// Expect Commit transaction
	mock.ExpectCommit()

	mockSvc := &MockInventoryService{
		DeductStockFunc: func(ctx context.Context, tx *gorm.DB, req domain.DeductStockRequest, userID string) error {
			return nil
		},
	}
	
	handler := NewInventoryHandler(db, mockSvc)

	router := setupTestRouter()
	router.POST("/deduct", handler.DeductStock)

	reqPayload := domain.DeductStockRequest{
		WarehouseID: 1,
		Items: []domain.ValidateStockItem{
			{ProductID: 10, Quantity: 5, Uom: "Hộp"},
		},
	}
	body, _ := json.Marshal(reqPayload)

	req, _ := http.NewRequest("POST", "/deduct", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.NoError(t, mock.ExpectationsWereMet())
}
