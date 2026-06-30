package services

import (
	"context"
	"testing"
	"time"

	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"gorm.io/gorm"
)

// Mock cho PromotionRepository
type MockPromotionRepo struct {
	mock.Mock
}

func (m *MockPromotionRepo) GetPromotionByCodeWithLock(ctx context.Context, tx *gorm.DB, code string) (*domain.Promotion, error) {
	args := m.Called(ctx, tx, code)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.Promotion), args.Error(1)
}

func (m *MockPromotionRepo) GetAvailablePromotions(ctx context.Context, tx *gorm.DB, customerID int64, orderTotal float64) ([]domain.Promotion, error) {
	args := m.Called(ctx, tx, customerID, orderTotal)
	return args.Get(0).([]domain.Promotion), args.Error(1)
}

func (m *MockPromotionRepo) GetPromotionsByCodesWithLock(ctx context.Context, tx *gorm.DB, codes []string) ([]domain.Promotion, error) {
	args := m.Called(ctx, tx, codes)
	return args.Get(0).([]domain.Promotion), args.Error(1)
}

func (m *MockPromotionRepo) IncrementUsageCount(ctx context.Context, tx *gorm.DB, code string) error {
	args := m.Called(ctx, tx, code)
	return args.Error(0)
}

func TestVerifyVoucher_Stackable_Success(t *testing.T) {
	mockRepo := new(MockPromotionRepo)
	svc := NewPromotionService(mockRepo)

	now := time.Now()
	
	// Test Case 1: Thành công áp dụng 3 mã
	// - MUA1T1: Gift (Tặng quà)
	// - GIAM100K: Cash (Giảm 100k)
	// - GIAM10: Percent (Giảm 10%)
	
	promos := []domain.Promotion{
		{
			ID: "1", Code: "MUA1T1", Status: "active", Type: "public",
			ValidFrom: now.Add(-time.Hour), ValidTo: now.Add(time.Hour),
			IsStackable: true, PromoGroup: "gift", CombinableGroups: `["cash", "percent", "freeship"]`,
			PromotionClass: "advanced",
			AdvancedRules: `{"condition":{"type":"buy_quantity","target_product_id":1,"min_quantity":1},"reward":{"type":"give_product","gift_product_id":2,"gift_quantity":1,"discount_percent":100},"is_multiply":false}`,
		},
		{
			ID: "2", Code: "GIAM100K", Status: "active", Type: "public",
			ValidFrom: now.Add(-time.Hour), ValidTo: now.Add(time.Hour),
			IsStackable: true, PromoGroup: "cash", CombinableGroups: `["gift", "percent", "freeship"]`,
			PromotionClass: "basic", DiscountType: "fixed_amount", Value: 100000, MinOrderValue: 200000,
		},
		{
			ID: "3", Code: "GIAM10", Status: "active", Type: "public",
			ValidFrom: now.Add(-time.Hour), ValidTo: now.Add(time.Hour),
			IsStackable: true, PromoGroup: "percent", CombinableGroups: `["gift", "cash", "freeship"]`,
			PromotionClass: "basic", DiscountType: "percentage", Value: 10, MinOrderValue: 200000, MaxDiscountValue: 50000,
		},
	}

	mockRepo.On("GetPromotionsByCodesWithLock", mock.Anything, mock.Anything, []string{"MUA1T1", "GIAM100K", "GIAM10"}).Return(promos, nil)

	req := domain.VerifyPromotionRequest{
		VoucherCodes: []string{"MUA1T1", "GIAM100K", "GIAM10"},
		OrderValue:   500000,
		CartItems: []domain.CartItem{
			{ProductID: 1, Quantity: 2, Price: 250000},
		},
	}

	res, err := svc.VerifyVoucher(context.Background(), nil, req)
	
	assert.NoError(t, err)
	assert.NotNil(t, res)
	assert.True(t, res.IsValid)
	
	// Validation tính toán:
	// Order: 500k
	// Bước 1: Gift -> Sinh ra 1 quà ID 2.
	// Bước 2: Cash -> 500k - 100k = 400k.
	// Bước 3: Percent -> Giảm 10% của 400k = 40k.
	// Tổng giảm = 100k + 40k = 140k. FinalAmount = 360k.
	assert.Equal(t, float64(140000), res.DiscountAmount)
	assert.Equal(t, float64(360000), res.FinalAmount)
	assert.Len(t, res.Gifts, 1)
	assert.Equal(t, int64(2), res.Gifts[0].ProductID)
}

func TestVerifyVoucher_Stackable_FailCrossLock(t *testing.T) {
	mockRepo := new(MockPromotionRepo)
	svc := NewPromotionService(mockRepo)
	now := time.Now()
	
	promos := []domain.Promotion{
		{
			ID: "1", Code: "MUA1T1", Status: "active", Type: "public",
			ValidFrom: now.Add(-time.Hour), ValidTo: now.Add(time.Hour),
			IsStackable: true, PromoGroup: "gift", CombinableGroups: `["freeship"]`, // KHÔNG CHO PHÉP cash
		},
		{
			ID: "2", Code: "GIAM100K", Status: "active", Type: "public",
			ValidFrom: now.Add(-time.Hour), ValidTo: now.Add(time.Hour),
			IsStackable: true, PromoGroup: "cash", CombinableGroups: `["gift", "percent", "freeship"]`,
		},
	}

	mockRepo.On("GetPromotionsByCodesWithLock", mock.Anything, mock.Anything, []string{"MUA1T1", "GIAM100K"}).Return(promos, nil)

	req := domain.VerifyPromotionRequest{
		VoucherCodes: []string{"MUA1T1", "GIAM100K"},
		OrderValue:   500000,
	}

	res, err := svc.VerifyVoucher(context.Background(), nil, req)
	
	assert.Error(t, err)
	assert.Nil(t, res)
	assert.Contains(t, err.Error(), "MUA1T1 không thể áp dụng chung")
}

func TestVerifyVoucher_Stackable_FailSameGroup(t *testing.T) {
	mockRepo := new(MockPromotionRepo)
	svc := NewPromotionService(mockRepo)
	now := time.Now()
	
	promos := []domain.Promotion{
		{
			ID: "1", Code: "CASH1", Status: "active", Type: "public",
			ValidFrom: now.Add(-time.Hour), ValidTo: now.Add(time.Hour),
			IsStackable: true, PromoGroup: "cash", CombinableGroups: `["cash"]`, 
		},
		{
			ID: "2", Code: "CASH2", Status: "active", Type: "public",
			ValidFrom: now.Add(-time.Hour), ValidTo: now.Add(time.Hour),
			IsStackable: true, PromoGroup: "cash", CombinableGroups: `["cash"]`,
		},
	}

	mockRepo.On("GetPromotionsByCodesWithLock", mock.Anything, mock.Anything, []string{"CASH1", "CASH2"}).Return(promos, nil)

	req := domain.VerifyPromotionRequest{
		VoucherCodes: []string{"CASH1", "CASH2"},
		OrderValue:   500000,
	}

	res, err := svc.VerifyVoucher(context.Background(), nil, req)
	
	assert.Error(t, err)
	assert.Nil(t, res)
	assert.Contains(t, err.Error(), "cùng nhóm (cash)")
}
