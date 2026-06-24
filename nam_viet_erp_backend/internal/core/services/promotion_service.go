package services

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/repository/postgres"
	"gorm.io/gorm"
)

type PromotionService interface {
	VerifyVoucher(ctx context.Context, tx *gorm.DB, req domain.VerifyPromotionRequest) (*domain.VerifyPromotionResponse, error)
	GetAutoSuggestPromotions(ctx context.Context, tx *gorm.DB) ([]domain.Promotion, error)
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

	if promo.Type == "personal" {
		if promo.CustomerID == nil || *promo.CustomerID != req.CustomerID {
			return nil, errors.New("mã khuyến mãi này không dành cho bạn")
		}
	}

	res := &domain.VerifyPromotionResponse{
		PromotionID: promo.ID,
		IsValid:     true,
		Message:     "Áp dụng mã khuyến mãi thành công",
	}

	if promo.PromotionClass == "advanced" && promo.AdvancedRules != "" {
		var rule map[string]interface{}
		if err := json.Unmarshal([]byte(promo.AdvancedRules), &rule); err != nil {
			return nil, errors.New("cấu hình khuyến mãi nâng cao bị lỗi")
		}

		condition, _ := rule["condition"].(map[string]interface{})
		reward, _ := rule["reward"].(map[string]interface{})
		isMultiply, _ := rule["is_multiply"].(bool)

		condType := condition["type"].(string)
		
		var times int = 0
		
		if condType == "buy_quantity" {
			targetProductID := int64(condition["target_product_id"].(float64))
			minQuantity := int(condition["min_quantity"].(float64))
			
			var cartQuantity int = 0
			for _, item := range req.CartItems {
				if item.ProductID == targetProductID {
					cartQuantity += item.Quantity
				}
			}
			
			if cartQuantity >= minQuantity {
				if isMultiply {
					times = cartQuantity / minQuantity
				} else {
					times = 1
				}
			} else {
				return nil, errors.New("chưa đạt số lượng sản phẩm yêu cầu")
			}
		} else if condType == "buy_amount" {
			minAmount := condition["min_amount"].(float64)
			if req.OrderValue >= minAmount {
				if isMultiply {
					times = int(req.OrderValue / minAmount)
				} else {
					times = 1
				}
			} else {
				return nil, errors.New("giá trị đơn hàng chưa đạt mức tối thiểu")
			}
		}

		if times > 0 {
			rewardType := reward["type"].(string)
			if rewardType == "give_product" {
				giftProductID := int64(reward["gift_product_id"].(float64))
				giftQty := int(reward["gift_quantity"].(float64))
				discountPct := int(reward["discount_percent"].(float64))
				
				res.Gifts = append(res.Gifts, domain.PromotionGift{
					ProductID:       giftProductID,
					Quantity:        giftQty * times,
					DiscountPercent: discountPct,
				})
			}
		}

	} else {
		// Basic Promotion Logic
		if req.OrderValue < promo.MinOrderValue {
			return nil, errors.New("giá trị đơn hàng chưa đạt mức tối thiểu")
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
		res.DiscountAmount = discountAmount
	}

	return res, nil
}

func (s *promotionService) GetAutoSuggestPromotions(ctx context.Context, tx *gorm.DB) ([]domain.Promotion, error) {
	return s.repo.GetActiveAdvancedPromotions(ctx, tx)
}
