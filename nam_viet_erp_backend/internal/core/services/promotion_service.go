package services

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"time"

	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/repository/postgres"
	"gorm.io/gorm"
)

type PromotionService interface {
	VerifyVoucher(ctx context.Context, tx *gorm.DB, req domain.VerifyPromotionRequest) (*domain.VerifyPromotionResponse, error)
	GetAutoSuggestPromotions(ctx context.Context, tx *gorm.DB, customerID int64, orderTotal float64) ([]domain.Promotion, error)
	IncrementUsageCount(ctx context.Context, tx *gorm.DB, code string) error
}

type promotionService struct {
	repo postgres.PromotionRepository
}

func NewPromotionService(repo postgres.PromotionRepository) PromotionService {
	return &promotionService{repo: repo}
}

func getEligibleSubtotal(tx *gorm.DB, promo *domain.Promotion, req domain.VerifyPromotionRequest, currentSubtotal float64) (float64, []int, error) {
	var eligibleIndices []int
	if promo.ApplyToScope == "all" || promo.ApplyToScope == "" {
		if len(req.CartItems) > 0 {
			total := 0.0
			for i, item := range req.CartItems {
				eligibleIndices = append(eligibleIndices, i)
				total += item.Price * float64(item.Quantity)
			}
			return total, eligibleIndices, nil
		}
		return currentSubtotal, eligibleIndices, nil
	}

	var rawIds []interface{}
	if promo.ApplyToIds != "" && promo.ApplyToIds != "null" {
		if err := json.Unmarshal([]byte(promo.ApplyToIds), &rawIds); err != nil {
			return 0, nil, nil
		}
	}

	if len(rawIds) == 0 {
		return currentSubtotal, nil, nil
	}

	validStrs := make(map[string]bool)
	for _, v := range rawIds {
		validStrs[fmt.Sprintf("%v", v)] = true
	}

	var productIDs []int64
	for _, item := range req.CartItems {
		productIDs = append(productIDs, item.ProductID)
	}

	if len(productIDs) == 0 {
		return 0, nil, nil
	}

	if promo.ApplyToScope == "product" {
		total := 0.0
		for i, item := range req.CartItems {
			idStr := fmt.Sprintf("%d", item.ProductID)
			if validStrs[idStr] {
				total += item.Price * float64(item.Quantity)
				eligibleIndices = append(eligibleIndices, i)
			}
		}
		return total, eligibleIndices, nil
	}

	type ProductInfo struct {
		ID               int64
		CategoryName     string
		ManufacturerName string
	}
	var products []ProductInfo
	if err := tx.Table("products").Select("id, category_name, manufacturer_name").Where("id IN ?", productIDs).Find(&products).Error; err != nil {
		return 0, nil, err
	}

	productInfoMap := make(map[int64]ProductInfo)
	for _, p := range products {
		productInfoMap[p.ID] = p
	}

	total := 0.0
	for i, item := range req.CartItems {
		info, exists := productInfoMap[item.ProductID]
		if !exists {
			continue
		}
		
		isValid := false
		if promo.ApplyToScope == "category" && validStrs[info.CategoryName] {
			isValid = true
		} else if promo.ApplyToScope == "brand" && validStrs[info.ManufacturerName] {
			isValid = true
		}

		if isValid {
			total += item.Price * float64(item.Quantity)
			eligibleIndices = append(eligibleIndices, i)
		}
	}

	return total, eligibleIndices, nil
}

func (s *promotionService) VerifyVoucher(ctx context.Context, tx *gorm.DB, req domain.VerifyPromotionRequest) (*domain.VerifyPromotionResponse, error) {
	if len(req.VoucherCodes) == 0 {
		return nil, errors.New("không có mã khuyến mãi nào được cung cấp")
	}

	// Option A: Fetch exact price from product_units if Uom is available
	if len(req.CartItems) > 0 {
		for i := range req.CartItems {
			if req.CartItems[i].Uom != "" {
				var dbPrice float64
				err := tx.Table("product_units").
					Select("price").
					Where("product_id = ? AND unit_name = ?", req.CartItems[i].ProductID, req.CartItems[i].Uom).
					Row().Scan(&dbPrice)
				if err != nil {
					return nil, fmt.Errorf("không tìm thấy giá cho sản phẩm ID %d với đơn vị %s", req.CartItems[i].ProductID, req.CartItems[i].Uom)
				}
				req.CartItems[i].Price = dbPrice
			}
		}
	}

	var subtotal float64
	for _, item := range req.CartItems {
		subtotal += item.Price * float64(item.Quantity)
	}

	// Fallback to OrderValue if CartItems is empty
	if len(req.CartItems) == 0 {
		subtotal = req.OrderValue - req.ShippingFee
	}

	originalSubtotal := subtotal

	promos, err := s.repo.GetPromotionsByCodesWithLock(ctx, tx, req.VoucherCodes)
	if err != nil {
		return nil, err
	}

	if len(promos) != len(req.VoucherCodes) {
		return nil, errors.New("một hoặc nhiều mã khuyến mãi không tồn tại")
	}

	now := time.Now()

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

	for _, promo := range promos {
		if !promo.IsStackable && len(promos) > 1 {
			return nil, errors.New("mã " + promo.Code + " là mã độc quyền, không thể áp dụng chung với các mã khác")
		}
	}

	groupCount := make(map[string]int)
	for _, promo := range promos {
		groupCount[promo.PromoGroup]++
		if groupCount[promo.PromoGroup] > 1 {
			return nil, errors.New("không thể áp dụng 2 mã cùng nhóm (" + promo.PromoGroup + ")")
		}
	}

	for i, promoA := range promos {
		var combinableA []string
		if promoA.CombinableGroups != "" {
			json.Unmarshal([]byte(promoA.CombinableGroups), &combinableA)
		}
		
		for j, promoB := range promos {
			if i == j {
				continue
			}
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

	res := &domain.VerifyPromotionResponse{
		IsValid: true,
		Message: "Áp dụng các mã khuyến mãi thành công",
	}

	if len(promos) > 0 {
		res.PromotionID = promos[0].ID
	}

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

	var totalDiscount float64

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
					if originalSubtotal >= minAmount && minAmount > 0 {
						if isMultiply {
							times = int(originalSubtotal / minAmount)
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

	if promoCash != nil {
		eligibleSubtotal, eligibleIndices, err := getEligibleSubtotal(tx, promoCash, req, subtotal)
		if err != nil {
			return nil, err
		}
		if eligibleSubtotal == 0 {
			return nil, errors.New("mã " + promoCash.Code + ": không có sản phẩm nào hợp lệ trong giỏ hàng")
		}
		if originalSubtotal < promoCash.MinOrderValue {
			return nil, errors.New("mã " + promoCash.Code + ": giá trị đơn hàng chưa đạt mức tối thiểu")
		}
		discountAmt := promoCash.Value
		if discountAmt > eligibleSubtotal {
			discountAmt = eligibleSubtotal
		}

		if eligibleSubtotal > 0 && len(eligibleIndices) > 0 {
			allocatedDiscount := 0.0
			for i, idx := range eligibleIndices {
				itemSubtotal := req.CartItems[idx].Price * float64(req.CartItems[idx].Quantity)
				if itemSubtotal > 0 {
					var itemDiscount float64
					if i == len(eligibleIndices)-1 {
						itemDiscount = discountAmt - allocatedDiscount
					} else {
						itemDiscount = math.Round((itemSubtotal / eligibleSubtotal) * discountAmt)
						allocatedDiscount += itemDiscount
					}
					req.CartItems[idx].Price -= itemDiscount / float64(req.CartItems[idx].Quantity)
					if req.CartItems[idx].Price < 0 {
						req.CartItems[idx].Price = 0
					}
				}
			}
		}

		subtotal -= discountAmt
		totalDiscount += discountAmt
	}

	if promoPercent != nil {
		eligibleSubtotal, eligibleIndices, err := getEligibleSubtotal(tx, promoPercent, req, subtotal)
		if err != nil {
			return nil, err
		}
		if eligibleSubtotal == 0 {
			return nil, errors.New("mã " + promoPercent.Code + ": không có sản phẩm nào hợp lệ trong giỏ hàng")
		}
		if originalSubtotal < promoPercent.MinOrderValue {
			return nil, errors.New("mã " + promoPercent.Code + ": giá trị đơn hàng chưa đạt mức tối thiểu")
		}
		discountAmt := math.Round((eligibleSubtotal * promoPercent.Value) / 100)
		if promoPercent.MaxDiscountValue > 0 && discountAmt > promoPercent.MaxDiscountValue {
			discountAmt = promoPercent.MaxDiscountValue
		}
		if discountAmt > eligibleSubtotal {
			discountAmt = eligibleSubtotal
		}

		if eligibleSubtotal > 0 && len(eligibleIndices) > 0 {
			allocatedDiscount := 0.0
			for i, idx := range eligibleIndices {
				itemSubtotal := req.CartItems[idx].Price * float64(req.CartItems[idx].Quantity)
				if itemSubtotal > 0 {
					var itemDiscount float64
					if i == len(eligibleIndices)-1 {
						itemDiscount = discountAmt - allocatedDiscount
					} else {
						itemDiscount = math.Round((itemSubtotal / eligibleSubtotal) * discountAmt)
						allocatedDiscount += itemDiscount
					}
					req.CartItems[idx].Price -= itemDiscount / float64(req.CartItems[idx].Quantity)
					if req.CartItems[idx].Price < 0 {
						req.CartItems[idx].Price = 0
					}
				}
			}
		}

		subtotal -= discountAmt
		totalDiscount += discountAmt
	}

	if promoFreeship != nil {
		if originalSubtotal < promoFreeship.MinOrderValue {
			return nil, errors.New("mã " + promoFreeship.Code + ": giá trị đơn hàng chưa đạt mức tối thiểu")
		}
		res.IsFreeship = true
		res.FreeshipMaxDiscount = promoFreeship.MaxDiscountValue
		
		if req.ShippingFee > 0 {
			fsDiscount := promoFreeship.MaxDiscountValue
			if fsDiscount > req.ShippingFee {
				fsDiscount = req.ShippingFee
			}
			totalDiscount += fsDiscount
			req.ShippingFee -= fsDiscount
		}
	}

	if subtotal < 0 {
		subtotal = 0
	}
	
	res.DiscountAmount = totalDiscount
	res.FinalAmount = subtotal + req.ShippingFee

	return res, nil
}

func (s *promotionService) IncrementUsageCount(ctx context.Context, tx *gorm.DB, code string) error {
	return s.repo.IncrementUsageCount(ctx, tx, code)
}

func (s *promotionService) GetAutoSuggestPromotions(ctx context.Context, tx *gorm.DB, customerID int64, orderTotal float64) ([]domain.Promotion, error) {
	return s.repo.GetAvailablePromotions(ctx, tx, customerID, orderTotal)
}
