package domain

import "time"

// PurchaseOrder represents a PO from supplier
type PurchaseOrder struct {
	ID          int64               `json:"id" gorm:"primaryKey;autoIncrement"`
	OrderCode   string              `json:"order_code" gorm:"uniqueIndex"`
	SupplierID  int64               `json:"supplier_id"`
	TotalAmount float64             `json:"total_amount"`
	Status      string              `json:"status"` // 'pending', 'completed', 'cancelled'
	Items       []PurchaseOrderItem `json:"items" gorm:"foreignKey:PurchaseOrderID"`
	CreatedAt   time.Time           `json:"created_at"`
	UpdatedAt   time.Time           `json:"updated_at"`
}

func (PurchaseOrder) TableName() string {
	return "purchase_orders"
}

// PurchaseOrderItem represents an item in a PO
type PurchaseOrderItem struct {
	ID               int64   `json:"id" gorm:"primaryKey;autoIncrement"`
	PurchaseOrderID  int64   `json:"purchase_order_id"`
	ProductID        int64   `json:"product_id"`
	QuantityOrdered  float64 `json:"quantity_ordered"`
	Unit             string  `json:"unit"`
	ConversionFactor float64 `json:"conversion_factor"`
	BaseQuantity     float64 `json:"base_quantity"` // Quantity in base unit
	UnitPrice        float64 `json:"unit_price"`
	IsBonus          bool    `json:"is_bonus"`
}

func (PurchaseOrderItem) TableName() string {
	return "purchase_order_items"
}

// CreatePurchaseOrderRequest
type CreatePurchaseOrderRequest struct {
	SupplierID int64               `json:"supplier_id" binding:"required"`
	Items      []CreatePOItemRequest `json:"items" binding:"required,dive"`
}

// CreatePOItemRequest
type CreatePOItemRequest struct {
	ProductID       int64   `json:"product_id" binding:"required"`
	QuantityOrdered float64 `json:"quantity_ordered" binding:"required,gt=0"`
	Unit            string  `json:"unit" binding:"required"`
	UnitPrice       float64 `json:"unit_price"`
	IsBonus         bool    `json:"is_bonus"`
}
