package postgres

import (
	"context"

	"github.com/namvieterp/backend/internal/core/domain"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type PromotionRepository interface {
	GetPromotionByCodeWithLock(ctx context.Context, tx *gorm.DB, code string) (*domain.Promotion, error)
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
