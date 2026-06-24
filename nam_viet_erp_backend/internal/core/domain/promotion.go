package domain

import "time"

// Promotion represents a discount voucher/campaign
type Promotion struct {
	ID               int64     `json:"id" gorm:"primaryKey"`
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
	VoucherCode string     `json:"voucher_code" binding:"required"`
	CustomerID  int64      `json:"customer_id"`
	OrderValue  float64    `json:"order_value" binding:"required"`
	CartItems   []CartItem `json:"cart_items"`
}

type PromotionGift struct {
	ProductID       int64 `json:"product_id"`
	Quantity        int   `json:"quantity"`
	DiscountPercent int   `json:"discount_percent"`
}

// VerifyPromotionResponse
type VerifyPromotionResponse struct {
	PromotionID    int64           `json:"promotion_id"`
	DiscountAmount float64         `json:"discount_amount"`
	Gifts          []PromotionGift `json:"gifts,omitempty"`
	IsValid        bool            `json:"is_valid"`
	Message        string          `json:"message"`
}
