package domain

import (
	"time"
)

// InventoryBatch represents the pivot between a warehouse, a product and a specific batch
type InventoryBatch struct {
	ID          int64     `json:"id" gorm:"primaryKey"`
	WarehouseID int64     `json:"warehouse_id"`
	ProductID   int64     `json:"product_id"`
	BatchID     int64     `json:"batch_id"`
	Quantity    float64   `json:"quantity"`
	UpdatedAt   time.Time `json:"updated_at"`

	// Preloaded associations
	Batch Batch `json:"batch" gorm:"foreignKey:BatchID"`
}

// TableName overrides the table name used by GORM
func (InventoryBatch) TableName() string {
	return "inventory_batches"
}

// Batch represents the actual lot/batch of a product
type Batch struct {
	ID                int64     `json:"id" gorm:"primaryKey"`
	ProductID         int64     `json:"product_id"`
	BatchCode         string    `json:"batch_code"`
	ExpiryDate        time.Time `json:"expiry_date"`
	ManufacturingDate time.Time `json:"manufacturing_date"`
	InboundPrice      float64   `json:"inbound_price"`
	CreatedAt         time.Time `json:"created_at"`
}

// TableName overrides the table name used by GORM
func (Batch) TableName() string {
	return "batches"
}

// InventoryTransaction represents a stock movement log
type InventoryTransaction struct {
	ID          int64     `json:"id" gorm:"primaryKey;autoIncrement"`
	WarehouseID int64     `json:"warehouse_id"`
	ProductID   int64     `json:"product_id"`
	BatchID     *int64    `json:"batch_id"` // can be null if not tracked by batch
	Type        string    `json:"type"`     // 'in', 'out', 'adjust'
	Quantity    float64   `json:"quantity"`
	RefID       *string   `json:"ref_id"`
	Note        *string   `json:"note"`
	CreatedAt   time.Time `json:"created_at"`
	CreatedBy   *string   `json:"created_by"` // UUID from auth
	Description *string   `json:"description"`
	ActionGroup *string   `json:"action_group"`
	UnitPrice   float64   `json:"unit_price"`
	PartnerID   *int64    `json:"partner_id"`
	TotalValue  float64   `json:"total_value"`
}

// TableName overrides the table name used by GORM
func (InventoryTransaction) TableName() string {
	return "inventory_transactions"
}



// -- Request/Response Models --

// ValidateStockItem represents a single item to validate
type ValidateStockItem struct {
	ProductID      int64   `json:"product_id" binding:"required"`
	Quantity       float64 `json:"quantity" binding:"required,gt=0"`
	Uom            string  `json:"uom" binding:"required"` // The requested unit of measurement
	WholesaleUnit  string  `json:"wholesale_unit"`         // Added for Purchasing
	ItemsPerCarton int     `json:"items_per_carton"`       // Added for Purchasing
}

// ValidateStockRequest is the payload for /inventory/validate
type ValidateStockRequest struct {
	WarehouseID int64               `json:"warehouse_id" binding:"required"`
	Items       []ValidateStockItem `json:"items" binding:"required,min=1,dive"`
}

// DeductStockRequest is the payload for /inventory/deduct
type DeductStockRequest struct {
	WarehouseID int64               `json:"warehouse_id" binding:"required"`
	Items       []ValidateStockItem `json:"items" binding:"required,min=1,dive"`
}

// ReceiptItem represents a single item in a receipt
type ReceiptItem struct {
	ProductID  int64     `json:"product_id" binding:"required"`
	Quantity   float64   `json:"quantity" binding:"required,gt=0"`
	BatchCode  string    `json:"batch_code" binding:"required"`
	ExpiryDate time.Time `json:"expiry_date" binding:"required"`
	UnitPrice  float64   `json:"unit_price"`
}

// CreateReceiptRequest is the payload for /inventory/receipt
type CreateReceiptRequest struct {
	WarehouseID int64         `json:"warehouse_id" binding:"required"`
	Note        string        `json:"note"`
	Items       []ReceiptItem `json:"items" binding:"required,min=1,dive"`
}
