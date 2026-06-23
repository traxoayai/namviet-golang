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

// MockOrderService implements services.OrderService
type MockOrderService struct {
	CreateSalesOrderFunc func(ctx context.Context, tx *gorm.DB, req domain.CreateOrderRequest, userID string) (*domain.Order, error)
}

func (m *MockOrderService) CreateSalesOrder(ctx context.Context, tx *gorm.DB, req domain.CreateOrderRequest, userID string) (*domain.Order, error) {
	if m.CreateSalesOrderFunc != nil {
		return m.CreateSalesOrderFunc(ctx, tx, req, userID)
	}
	return nil, nil
}

func setupOrderMockDB(t *testing.T) (*gorm.DB, sqlmock.Sqlmock) {
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

func TestCreateSalesOrder_Success(t *testing.T) {
	db, mock := setupOrderMockDB(t)

	mock.ExpectBegin()
	mock.ExpectCommit()

	mockSvc := &MockOrderService{
		CreateSalesOrderFunc: func(ctx context.Context, tx *gorm.DB, req domain.CreateOrderRequest, userID string) (*domain.Order, error) {
			return &domain.Order{
				ID:          1,
				OrderCode:   "SO-TEST",
				TotalAmount: 100000,
			}, nil
		},
	}

	handler := NewOrderHandler(db, mockSvc)
	router := gin.Default()
	router.POST("/orders", handler.CreateSalesOrder)

	reqPayload := domain.CreateOrderRequest{
		CustomerID:    1,
		WarehouseID:   1,
		PaymentMethod: "cash",
		Items: []domain.OrderItemRequest{
			{ProductID: 10, Uom: "Hộp", Quantity: 2, UnitPrice: 50000},
		},
	}
	body, _ := json.Marshal(reqPayload)

	req, _ := http.NewRequest("POST", "/orders", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.NoError(t, mock.ExpectationsWereMet())

	var response domain.Order
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, int64(1), response.ID)
	assert.Equal(t, "SO-TEST", response.OrderCode)
}
