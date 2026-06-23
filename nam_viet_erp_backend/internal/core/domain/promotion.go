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
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}

func (Promotion) TableName() string {
	return "promotions"
}

// VerifyPromotionRequest
type VerifyPromotionRequest struct {
	VoucherCode string  `json:"voucher_code" binding:"required"`
	CustomerID  int64   `json:"customer_id"`
	OrderValue  float64 `json:"order_value" binding:"required"`
}

// VerifyPromotionResponse
type VerifyPromotionResponse struct {
	PromotionID    int64   `json:"promotion_id"`
	DiscountAmount float64 `json:"discount_amount"`
	IsValid        bool    `json:"is_valid"`
	Message        string  `json:"message"`
}
