package domain

import "time"

// PurchaseOrder represents a PO from supplier
type PurchaseOrder struct {
	ID          int64               `json:"id" gorm:"primaryKey;autoIncrement"`
	OrderCode      string              `json:"order_code" gorm:"column:code;uniqueIndex"`
	SupplierID  int64               `json:"supplier_id"`
	TotalAmount    float64             `json:"total_amount"`
	FinalAmount    float64             `json:"final_amount"`
	DeliveryStatus string              `json:"delivery_status" gorm:"column:delivery_status"`
	PaymentStatus  string              `json:"payment_status"`
	Note           string              `json:"note"`
	Items          []PurchaseOrderItem `json:"items" gorm:"foreignKey:PurchaseOrderID"`
	CreatedAt      time.Time           `json:"created_at"`
	UpdatedAt      time.Time           `json:"updated_at"`
}

func (PurchaseOrder) TableName() string {
	return "purchase_orders"
}

// PurchaseOrderItem represents an item in a PO
type PurchaseOrderItem struct {
	ID               int64   `json:"id" gorm:"primaryKey;autoIncrement"`
	PurchaseOrderID  int64   `json:"purchase_order_id" gorm:"column:po_id"`
	ProductID        int64   `json:"product_id"`
	QuantityOrdered  float64 `json:"quantity_ordered"`
	Unit             string  `json:"unit"`
	ConversionFactor float64 `json:"conversion_factor"`
	BaseQuantity     float64 `json:"base_quantity"` // Quantity in base unit
	UnitPrice        float64 `json:"unit_price"`
	IsBonus          bool    `json:"is_bonus" gorm:"-"`
}

func (PurchaseOrderItem) TableName() string {
	return "purchase_order_items"
}

// CreatePurchaseOrderRequest
type CreatePurchaseOrderRequest struct {
	SupplierID int64               `json:"supplier_id" binding:"required"`
	Items      []CreatePOItemRequest `json:"items" binding:"required,dive"`
}

// AutoReplenishResponse represents the result of the Min-Max auto generation
type AutoReplenishResponse struct {
	Message        string                 `json:"message"`
	CreatedPOCount int                    `json:"created_po_count"`
	GeneratedPOs   []AutoReplenishPODTO   `json:"generated_pos"`
}

type AutoReplenishPODTO struct {
	ID             int64                  `json:"id"`
	OrderCode      string                 `json:"order_code"`
	SupplierID     int64                  `json:"supplier_id"`
	DeliveryStatus string                 `json:"delivery_status"`
	PaymentStatus  string                 `json:"payment_status"`
	TotalAmount    float64                `json:"total_amount"`
	FinalAmount    float64                `json:"final_amount"`
	Items          []AutoReplenishItemDTO `json:"items"`
}

type AutoReplenishItemDTO struct {
	ProductID                int64   `json:"product_id"`
	ProductName              string  `json:"product_name"`
	ImageURL                 string  `json:"image_url"`
	QuantityOrdered          int     `json:"quantity_ordered"`
	Unit                     string  `json:"unit"`
	UnitPrice                float64 `json:"unit_price"`
	ConversionFactor         float64 `json:"conversion_factor"`
	BaseQuantity             float64 `json:"base_quantity"`
	CurrentStockBase         float64 `json:"current_stock_base"`
	AvgMonthlySalesBase      float64 `json:"avg_monthly_sales_base"`
	CurrentStockWholesale    float64 `json:"current_stock_wholesale"`
	AvgMonthlySalesWholesale float64 `json:"avg_monthly_sales_wholesale"`
}

type ProductReplenishDTO struct {
	ProductID           int64   `gorm:"column:product_id"`
	ProductName         string  `gorm:"column:name"`
	ImageURL            string  `gorm:"column:image_url"`
	SupplierID          int64   `gorm:"column:supplier_id"`
	UnitName            string  `gorm:"column:unit_name"`
	ConversionFactor    float64 `gorm:"column:conversion_factor"`
	UnitPrice           float64 `gorm:"column:unit_price"`
	QuantityNeeded      int     `gorm:"column:quantity_needed"`
	CurrentStockBase    float64 `gorm:"column:current_stock_base"`
	AvgMonthlySalesBase float64 `gorm:"column:avg_monthly_sales_base"`
}

// DTOs for GET /api/v1/purchasing/orders/:id
type PurchaseOrderDetailDTO struct {
	ID             int64                        `json:"id"`
	OrderCode      string                       `json:"order_code"`
	SupplierID     int64                        `json:"supplier_id"`
	DeliveryStatus string                       `json:"delivery_status"`
	PaymentStatus  string                       `json:"payment_status"`
	TotalAmount    float64                      `json:"total_amount"`
	FinalAmount    float64                      `json:"final_amount"`
	Note           string                       `json:"note"`
	CreatedAt      time.Time                    `json:"created_at"`
	UpdatedAt      time.Time                    `json:"updated_at"`
	Items          []PurchaseOrderItemDetailDTO `json:"items" gorm:"-"`
}

type PurchaseOrderItemDetailDTO struct {
	ID               int64   `json:"id"`
	ProductID        int64   `json:"product_id"`
	ProductName      string  `json:"name"`
	ImageURL         string  `json:"image_url"`
	QuantityOrdered  float64 `json:"quantity_ordered"`
	Unit             string  `json:"unit"`
	UnitPrice        float64 `json:"unit_price"`
	ConversionFactor float64 `json:"conversion_factor"`
	BaseQuantity     float64 `json:"base_quantity"`
	IsBonus          bool    `json:"is_bonus"`
	TotalStock       float64 `json:"total_stock"`
	AvgMonthlySold   float64 `json:"avg_monthly_sold"`
}

// CreatePOItemRequest
type CreatePOItemRequest struct {
	ProductID       int64   `json:"product_id" binding:"required"`
	QuantityOrdered float64 `json:"quantity_ordered" binding:"required,gt=0"`
	Unit            string  `json:"unit" binding:"required"`
	UnitPrice       float64 `json:"unit_price"`
	IsBonus         bool    `json:"is_bonus"`
}
