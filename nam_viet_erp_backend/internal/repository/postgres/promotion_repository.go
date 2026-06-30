package postgres

import (
	"context"
	"errors"

	"github.com/namvieterp/backend/internal/core/domain"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type PromotionRepository interface {
	GetPromotionByCodeWithLock(ctx context.Context, tx *gorm.DB, code string) (*domain.Promotion, error)
	GetAvailablePromotions(ctx context.Context, tx *gorm.DB, customerID int64, orderTotal float64) ([]domain.Promotion, error)
	GetPromotionsByCodesWithLock(ctx context.Context, tx *gorm.DB, codes []string) ([]domain.Promotion, error)
	IncrementUsageCount(ctx context.Context, tx *gorm.DB, code string) error
}

type promotionRepository struct{}

func NewPromotionRepository() PromotionRepository {
	return &promotionRepository{}
}

func (r *promotionRepository) GetPromotionByCodeWithLock(ctx context.Context, tx *gorm.DB, code string) (*domain.Promotion, error) {
	var promo domain.Promotion
	err := tx.WithContext(ctx).
		Clauses(clause.Locking{Strength: "UPDATE"}).
		Where("code = ?", code).
		First(&promo).Error
	if err != nil {
		return nil, err
	}
	return &promo, nil
}

func (r *promotionRepository) GetPromotionsByCodesWithLock(ctx context.Context, tx *gorm.DB, codes []string) ([]domain.Promotion, error) {
	var promos []domain.Promotion
	err := tx.WithContext(ctx).
		Clauses(clause.Locking{Strength: "UPDATE"}).
		Where("code IN ?", codes).
		Find(&promos).Error
	if err != nil {
		return nil, err
	}
	return promos, nil
}

func (r *promotionRepository) GetAvailablePromotions(ctx context.Context, tx *gorm.DB, customerID int64, orderTotal float64) ([]domain.Promotion, error) {
	var promos []domain.Promotion
	
	// Query to get available promotions
	// 1. Must be active
	// 2. valid_to must be >= NOW()
	// 3. For 'personal' type, it must match the customer_id
	// 4. (Optional but good) min_order_value should be <= orderTotal
	
	query := tx.WithContext(ctx).
		Where("status = ? AND valid_to >= NOW()", "active").
		Where("(type = 'public' OR (type = 'personal' AND customer_id = ?))", customerID)
		
	// Note: We leave usage_limit checking for later validation, or we can add:
	// Where("total_usage_limit IS NULL OR usage_count < total_usage_limit")
	
	err := query.Find(&promos).Error
	
	if err != nil {
		return nil, err
	}
	
	// Filter by min_order_value
	var validPromos []domain.Promotion
	for _, p := range promos {
		if orderTotal >= p.MinOrderValue {
			validPromos = append(validPromos, p)
		}
	}
	
	return validPromos, nil
}

// IncrementUsageCount tăng usage_count lên 1 một cách atomic, an toàn cho concurrent requests
func (r *promotionRepository) IncrementUsageCount(ctx context.Context, tx *gorm.DB, code string) error {
	result := tx.WithContext(ctx).Model(&domain.Promotion{}).
		Where("code = ?", code).
		UpdateColumn("usage_count", gorm.Expr("usage_count + 1"))
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return errors.New("không tìm thấy mã khuyến mãi để cập nhật")
	}
	return nil
}
