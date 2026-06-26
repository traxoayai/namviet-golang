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
	IncrementUsageCount(ctx context.Context, tx *gorm.DB, code string) error
}

type promotionService struct {
	repo postgres.PromotionRepository
}

func NewPromotionService(repo postgres.PromotionRepository) PromotionService {
	return &promotionService{repo: repo}
}

func (s *promotionService) VerifyVoucher(ctx context.Context, tx *gorm.DB, req domain.VerifyPromotionRequest) (*domain.VerifyPromotionResponse, error) {
	if len(req.VoucherCodes) == 0 {
		return nil, errors.New("không có mã khuyến mãi nào được cung cấp")
	}

	promos, err := s.repo.GetPromotionsByCodesWithLock(ctx, tx, req.VoucherCodes)
	if err != nil {
		return nil, err
	}

	if len(promos) != len(req.VoucherCodes) {
		return nil, errors.New("một hoặc nhiều mã khuyến mãi không tồn tại")
	}

	now := time.Now()

	// 1. Validations cơ bản cho từng mã
	for _, promo := range promos {
		if promo.Status != "active" {
			return nil, errors.New("Mã giảm giá đã bị khóa hoặc không còn hiệu lực.")
		}
		if now.After(promo.ValidTo) {
			return nil, errors.New("Mã giảm giá đã hết hạn sử dụng.")
		}
		if now.Before(promo.ValidFrom) {
			return nil, errors.New("Mã giảm giá chưa đến giờ áp dụng.")
		}
		if promo.TotalUsageLimit > 0 && promo.UsageCount >= promo.TotalUsageLimit {
			return nil, errors.New("Mã giảm giá đã đạt giới hạn số lượt sử dụng.")
		}
		if promo.Type == "personal" {
			if promo.CustomerID == nil || *promo.CustomerID != req.CustomerID {
				return nil, errors.New("mã " + promo.Code + " không dành cho bạn")
			}
		}
	}

	// 2. Cross-Validation (Khóa chéo)
	// a. Check is_stackable
	for _, promo := range promos {
		if !promo.IsStackable && len(promos) > 1 {
			return nil, errors.New("mã " + promo.Code + " là mã độc quyền, không thể áp dụng chung với các mã khác")
		}
	}

	// b. Check trùng nhóm (cùng promo_group)
	groupCount := make(map[string]int)
	for _, promo := range promos {
		groupCount[promo.PromoGroup]++
		if groupCount[promo.PromoGroup] > 1 {
			return nil, errors.New("không thể áp dụng 2 mã cùng nhóm (" + promo.PromoGroup + ")")
		}
	}

	// c. Check combinable_groups chéo nhau
	for i, promoA := range promos {
		var combinableA []string
		if promoA.CombinableGroups != "" {
			json.Unmarshal([]byte(promoA.CombinableGroups), &combinableA)
		}
		
		for j, promoB := range promos {
			if i == j {
				continue
			}
			
			// Kiểm tra xem promoB.PromoGroup có nằm trong allowed array của promoA không
			isAllowed := false
			for _, allowedGroup := range combinableA {
				if allowedGroup == promoB.PromoGroup {
					isAllowed = true
					break
				}
			}
			if !isAllowed {
				return nil, errors.New("mã " + promoA.Code + " không thể áp dụng chung với loại mã " + promoB.PromoGroup)
			}
		}
	}

	// 3. Calculation Logic (Trình tự: Gift -> Cash -> Percent -> Freeship)
	res := &domain.VerifyPromotionResponse{
		IsValid: true,
		Message: "Áp dụng các mã khuyến mãi thành công",
	}

	if len(promos) > 0 {
		res.PromotionID = promos[0].ID // Backward compatibility
	}

	// Phân loại mã vào các bucket
	var promoGift, promoCash, promoPercent, promoFreeship *domain.Promotion
	for i := range promos {
		p := &promos[i]
		switch p.PromoGroup {
		case "gift":
			promoGift = p
		case "cash":
			promoCash = p
		case "percent":
			promoPercent = p
		case "freeship":
			promoFreeship = p
		}
	}

	subtotal := req.OrderValue
	var totalDiscount float64

	// Bước 1: Gift
	if promoGift != nil {
		if promoGift.PromotionClass == "advanced" && promoGift.AdvancedRules != "" {
			var rule map[string]interface{}
			if err := json.Unmarshal([]byte(promoGift.AdvancedRules), &rule); err == nil {
				condition, _ := rule["condition"].(map[string]interface{})
				reward, _ := rule["reward"].(map[string]interface{})
				isMultiply, _ := rule["is_multiply"].(bool)

				condType, _ := condition["type"].(string)
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
					
					if cartQuantity >= minQuantity && minQuantity > 0 {
						if isMultiply {
							times = cartQuantity / minQuantity
						} else {
							times = 1
						}
					} else {
						return nil, errors.New("mã " + promoGift.Code + ": chưa đạt số lượng sản phẩm yêu cầu")
					}
				} else if condType == "buy_amount" {
					minAmount := condition["min_amount"].(float64)
					if req.OrderValue >= minAmount && minAmount > 0 {
						if isMultiply {
							times = int(req.OrderValue / minAmount)
						} else {
							times = 1
						}
					} else {
						return nil, errors.New("mã " + promoGift.Code + ": giá trị đơn hàng chưa đạt mức tối thiểu")
					}
				}

				if times > 0 {
					rewardType, _ := reward["type"].(string)
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
			}
		}
	}

	// Bước 2: Cash
	if promoCash != nil {
		if req.OrderValue < promoCash.MinOrderValue {
			return nil, errors.New("mã " + promoCash.Code + ": giá trị đơn hàng chưa đạt mức tối thiểu")
		}
		discountAmt := promoCash.Value
		if discountAmt > subtotal {
			discountAmt = subtotal
		}
		subtotal -= discountAmt
		totalDiscount += discountAmt
	}

	// Bước 3: Percent
	if promoPercent != nil {
		if req.OrderValue < promoPercent.MinOrderValue {
			return nil, errors.New("mã " + promoPercent.Code + ": giá trị đơn hàng chưa đạt mức tối thiểu")
		}
		discountAmt := (subtotal * promoPercent.Value) / 100
		if promoPercent.MaxDiscountValue > 0 && discountAmt > promoPercent.MaxDiscountValue {
			discountAmt = promoPercent.MaxDiscountValue
		}
		if discountAmt > subtotal {
			discountAmt = subtotal
		}
		subtotal -= discountAmt
		totalDiscount += discountAmt
	}

	// Bước 4: Freeship
	if promoFreeship != nil {
		if req.OrderValue < promoFreeship.MinOrderValue {
			return nil, errors.New("mã " + promoFreeship.Code + ": giá trị đơn hàng chưa đạt mức tối thiểu")
		}
		res.IsFreeship = true
		res.FreeshipMaxDiscount = promoFreeship.MaxDiscountValue
	}

	res.DiscountAmount = totalDiscount
	res.FinalAmount = subtotal

	return res, nil
}

func (s *promotionService) IncrementUsageCount(ctx context.Context, tx *gorm.DB, code string) error {
	return s.repo.IncrementUsageCount(ctx, tx, code)
}

func (s *promotionService) GetAutoSuggestPromotions(ctx context.Context, tx *gorm.DB) ([]domain.Promotion, error) {
	return s.repo.GetActiveAdvancedPromotions(ctx, tx)
}
