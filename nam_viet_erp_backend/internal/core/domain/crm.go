package domain

import "time"

// Customer represents a buyer
type Customer struct {
	ID            int64     `json:"id" gorm:"primaryKey"`
	Name          string    `json:"name"`
	Phone         string    `json:"phone"`
	Email         string    `json:"email"`
	LoyaltyPoints int       `json:"loyalty_points"`
	Status        string    `json:"status"`
	CustomerType  string    `json:"customer_type"` // B2C, B2B
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

func (Customer) TableName() string {
	return "customers"
}

// CustomerSegment represents a dynamic or static group
type CustomerSegment struct {
	ID          int64     `json:"id" gorm:"primaryKey"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Type        string    `json:"type"` // static, dynamic
	IsActive    bool      `json:"is_active"`
	CreatedAt   time.Time `json:"created_at"`
}

func (CustomerSegment) TableName() string {
	return "customer_segments"
}

// EarnLoyaltyRequest payload
type EarnLoyaltyRequest struct {
	CustomerID int64   `json:"customer_id" binding:"required"`
	OrderID    string  `json:"order_id" binding:"required"`
	Amount     float64 `json:"amount" binding:"required,gt=0"`
}
