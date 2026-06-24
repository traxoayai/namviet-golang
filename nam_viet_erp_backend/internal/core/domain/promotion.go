package domain

import "time"

// Promotion represents a discount voucher/campaign
type Promotion struct {
	ID               string    `json:"id" gorm:"primaryKey;type:uuid"`
	Code             string    `json:"code" gorm:"uniqueIndex"`
	DiscountType     string    `json:"discount_type"` // 'percentage' or 'fixed_amount'
	Value            float64   `json:"value"`
	MinOrderValue    float64   `json:"min_order_value"`
	MaxDiscountValue float64   `json:"max_discount_value"`
	ValidFrom        time.Time `json:"valid_from"`
	ValidTo          time.Time `json:"valid_to"`
	UsageCount       int       `json:"usage_count"`
	TotalUsageLimit  int       `json:"total_usage_limit"`
	Status           string    `json:"status"` // 'active', 'inactive'
	Type             string    `json:"type"`   // 'public', 'personal'
	CustomerID       *int64    `json:"customer_id"`
	PromotionClass   string    `json:"promotion_class" gorm:"column:promotion_class;default:basic"`
	AdvancedRules    string    `json:"advanced_rules" gorm:"column:advanced_rules;type:jsonb"`
	PromoGroup       string    `json:"promo_group" gorm:"column:promo_group;default:cash"`
	CombinableGroups string    `json:"combinable_groups" gorm:"column:combinable_groups;type:jsonb;default:'[]'"`
	IsStackable      bool      `json:"is_stackable" gorm:"column:is_stackable;default:true"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}

func (Promotion) TableName() string {
	return "promotions"
}

type CartItem struct {
	ProductID int64   `json:"product_id"`
	Quantity  int     `json:"quantity"`
	Price     float64 `json:"price"`
}

// VerifyPromotionRequest
type VerifyPromotionRequest struct {
	VoucherCodes []string   `json:"voucher_codes" binding:"required"`
	CustomerID   int64      `json:"customer_id"`
	OrderValue   float64    `json:"order_value" binding:"required"`
	CartItems    []CartItem `json:"cart_items"`
}

type PromotionGift struct {
	ProductID       int64 `json:"product_id"`
	Quantity        int   `json:"quantity"`
	DiscountPercent int   `json:"discount_percent"`
}

// VerifyPromotionResponse
type VerifyPromotionResponse struct {
	PromotionID         string          `json:"promotion_id"` // deprecated for multiple
	DiscountAmount      float64         `json:"discount_amount"`
	FinalAmount         float64         `json:"final_amount"`
	Gifts               []PromotionGift `json:"gifts,omitempty"`
	IsFreeship          bool            `json:"is_freeship"`
	FreeshipMaxDiscount float64         `json:"freeship_max_discount"`
	IsValid             bool            `json:"is_valid"`
	Message             string          `json:"message"`
}
