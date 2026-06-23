package services

import (
	"context"
	"errors"
	"time"

	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/repository/postgres"
	"gorm.io/gorm"
)

type PromotionService interface {
	VerifyVoucher(ctx context.Context, tx *gorm.DB, req domain.VerifyPromotionRequest) (*domain.VerifyPromotionResponse, error)
}

type promotionService struct {
	repo postgres.PromotionRepository
}

func NewPromotionService(repo postgres.PromotionRepository) PromotionService {
	return &promotionService{repo: repo}
}

func (s *promotionService) VerifyVoucher(ctx context.Context, tx *gorm.DB, req domain.VerifyPromotionRequest) (*domain.VerifyPromotionResponse, error) {
	promo, err := s.repo.GetPromotionByCodeWithLock(ctx, tx, req.VoucherCode)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("mã khuyến mãi không tồn tại")
		}
		return nil, err
	}

	if promo.Status != "active" {
		return nil, errors.New("mã khuyến mãi không còn hoạt động")
	}

	now := time.Now()
	if now.Before(promo.ValidFrom) || now.After(promo.ValidTo) {
		return nil, errors.New("mã khuyến mãi đã hết hạn hoặc chưa đến giờ áp dụng")
	}

	if promo.UsageCount >= promo.TotalUsageLimit {
		return nil, errors.New("mã khuyến mãi đã hết lượt sử dụng")
	}

	if req.OrderValue < promo.MinOrderValue {
		return nil, errors.New("giá trị đơn hàng chưa đạt mức tối thiểu")
	}

	if promo.Type == "personal" {
		if promo.CustomerID == nil || *promo.CustomerID != req.CustomerID {
			return nil, errors.New("mã khuyến mãi này không dành cho bạn")
		}
	}

	var discountAmount float64
	if promo.DiscountType == "percentage" {
		discountAmount = (req.OrderValue * promo.Value) / 100
		if discountAmount > promo.MaxDiscountValue && promo.MaxDiscountValue > 0 {
			discountAmount = promo.MaxDiscountValue
		}
	} else if promo.DiscountType == "fixed_amount" {
		discountAmount = promo.Value
		if discountAmount > req.OrderValue {
			discountAmount = req.OrderValue
		}
	}

	return &domain.VerifyPromotionResponse{
		PromotionID:    promo.ID,
		DiscountAmount: discountAmount,
		IsValid:        true,
		Message:        "Áp dụng mã khuyến mãi thành công",
	}, nil
}
