package domain

import "time"

// Order represents a sales order
type Order struct {
	ID             string    `json:"id" gorm:"primaryKey;type:uuid"`
	OrderCode      string    `json:"order_code"`
	CustomerID     int64     `json:"customer_id"`
	TotalAmount    float64   `json:"total_amount"`
	DiscountAmount float64   `json:"discount_amount"`
	FinalAmount    float64   `json:"final_amount"`
	Status         string    `json:"status"` // pending, confirmed, completed
	PaymentMethod  string    `json:"payment_method"`
	PaymentStatus  string    `json:"payment_status"` // unpaid, paid
	TrackingCode   string    `json:"tracking_code"`
	DeliveryStatus string    `json:"delivery_status"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`

	Items []OrderItem `json:"items" gorm:"foreignKey:OrderID"`
}

// TableName overrides the table name
func (Order) TableName() string {
	return "orders"
}

// OrderItem represents an item in the order
type OrderItem struct {
	ID               int64   `json:"id" gorm:"primaryKey;autoIncrement"`
	OrderID          string  `json:"order_id"`
	ProductID        int64   `json:"product_id"`
	Uom              string  `json:"uom"`
	Quantity         float64 `json:"quantity"`
	ConversionFactor float64 `json:"conversion_factor"`
	UnitPrice        float64 `json:"unit_price"`
	TotalPrice       float64 `json:"total_price"`
}

// TableName overrides the table name
func (OrderItem) TableName() string {
	return "order_items"
}



// -- Request / Response --

type OrderItemRequest struct {
	ProductID int64   `json:"product_id" binding:"required"`
	Uom       string  `json:"uom" binding:"required"`
	Quantity  float64 `json:"quantity" binding:"required,gt=0"`
	UnitPrice float64 `json:"unit_price" binding:"required,gte=0"`
}

type CreateOrderRequest struct {
	CustomerID    int64              `json:"customer_id" binding:"required"`
	WarehouseID   int64              `json:"warehouse_id" binding:"required"`
	PaymentMethod string             `json:"payment_method" binding:"required"`
	VoucherCode   string             `json:"voucher_code"`
	Items         []OrderItemRequest `json:"items" binding:"required,min=1,dive"`
}
