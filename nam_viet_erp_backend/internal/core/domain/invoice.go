package domain

import (
	"time"
)

type InvoicePayload struct {
	ID                    *int64               `json:"id"`
	InvoiceNumber         string               `json:"invoice_number"`
	InvoiceSymbol         string               `json:"invoice_symbol"`
	InvoiceDate           string               `json:"invoice_date"`
	SupplierID            *int64               `json:"supplier_id"`
	FileURL               string               `json:"file_url"`
	SupplierNameRaw       string               `json:"supplier_name_raw"`
	SupplierTaxCode       string               `json:"supplier_tax_code"`
	SupplierAddressRaw    string               `json:"supplier_address_raw"`
	ParsedData            interface{}          `json:"parsed_data"`
	TotalPriceExcludesVat float64              `json:"total_price_excludes_vat"`
	TotalTradeDiscount    float64              `json:"total_trade_discount"`
	TotalFeeAmount        float64              `json:"total_fee_amount"`
	TotalAmountPreTax     float64              `json:"total_amount_pre_tax"`
	TaxAmount             float64              `json:"tax_amount"`
	TotalAmountPostTax    float64              `json:"total_amount_post_tax"`
	ItemsData             []InvoiceItemPayload `json:"items_data"`
	Direction             string               `json:"direction"`
	Status                string               `json:"status"`
	BuyerName             string               `json:"buyer_name"`
	BuyerTaxCode          string               `json:"buyer_tax_code"`
	BuyerAddress          string               `json:"buyer_address"`
	BuyerEmail            string               `json:"buyer_email"`
	OrderID               *string              `json:"order_id"`
	IsDraft               bool                 `json:"is_draft"`
}

type InvoiceItemPayload struct {
	ID                    *int64  `json:"id"`
	ProductID             *int64  `json:"product_id"`
	ProductNameRaw        string  `json:"product_name_raw"`
	VendorUnit            string  `json:"vendor_unit"`
	InternalProductUnitId *int64  `json:"internal_product_unit_id"`
	ProductUnitID         *int64  `json:"product_unit_id"`
	Quantity              float64 `json:"quantity"`
	QuantityBuyer         float64 `json:"quantity_buyer"`
	UnitPrice             float64 `json:"unit_price"`
	TotalAmountPreVat     float64 `json:"total_amount_pre_vat"`
	VatRate               float64 `json:"vat_rate"`
	DiscountAmount        float64 `json:"discount_amount"`
}

type FinanceInvoice struct {
	ID                    int64       `gorm:"primaryKey;autoIncrement" json:"id"`
	InvoiceNumber         string      `gorm:"type:text" json:"invoice_number"`
	InvoiceSymbol         string      `gorm:"type:text" json:"invoice_symbol"`
	InvoiceDate           time.Time   `gorm:"type:date" json:"invoice_date"`
	SupplierNameRaw       string      `gorm:"type:text" json:"supplier_name_raw"`
	SupplierTaxCode       string      `gorm:"type:text" json:"supplier_tax_code"`
	SupplierID            *int64      `gorm:"type:bigint" json:"supplier_id"`
	TotalAmountPreTax     float64     `gorm:"type:numeric" json:"total_amount_pre_tax"`
	TaxAmount             float64     `gorm:"type:numeric" json:"tax_amount"`
	TotalAmountPostTax    float64     `gorm:"type:numeric" json:"total_amount_post_tax"`
	TotalPriceExcludesVat float64     `gorm:"type:numeric" json:"total_price_excludes_vat"`
	TotalTradeDiscount    float64     `gorm:"type:numeric" json:"total_trade_discount"`
	TotalFeeAmount        float64     `gorm:"type:numeric" json:"total_fee_amount"`
	ParsedData            interface{} `gorm:"type:jsonb;serializer:json" json:"parsed_data"`
	FileURL               string      `gorm:"type:text" json:"file_url"`
	FileType              string      `gorm:"type:text" json:"file_type"`
	Status                string      `gorm:"type:text" json:"status"`
	Direction             string      `gorm:"type:text" json:"direction"`
	PaidAmount            float64     `gorm:"type:numeric;default:0" json:"paid_amount"`
	BuyerName             string      `gorm:"type:text" json:"buyer_name"`
	BuyerTaxCode          string      `gorm:"type:text" json:"buyer_tax_code"`
	BuyerAddress          string      `gorm:"type:text" json:"buyer_address"`
	BuyerEmail            string      `gorm:"type:text" json:"buyer_email"`
	OrderID               *string     `gorm:"type:uuid" json:"order_id"`
	SepayReferenceCode    *string     `gorm:"type:text" json:"sepay_reference_code"`
	SepayTrackingCode     *string     `gorm:"type:text" json:"sepay_tracking_code"`
	ItemsJSON             interface{} `gorm:"type:jsonb;serializer:json;column:items_json" json:"items_json"`
}

func (FinanceInvoice) TableName() string {
	return "finance_invoices"
}

type FinanceInvoiceItem struct {
	ID                int64   `gorm:"primaryKey;autoIncrement"`
	InvoiceID         int64   `gorm:"type:bigint"`
	ProductID         *int64  `gorm:"type:bigint"`
	ProductUnitID     *int64  `gorm:"type:bigint;column:product_unit_id"`
	VendorProductName string  `gorm:"type:text"`
	VendorUnit        string  `gorm:"type:text"`
	Quantity          float64 `gorm:"type:numeric"`
	QuantityBuyer     float64 `gorm:"type:numeric"`
	PreVatPrice       float64 `gorm:"type:numeric"`
	TotalAmountPreVat float64 `gorm:"type:numeric"`
	VatRate           float64 `gorm:"type:numeric"`
	DiscountAmount    float64 `gorm:"type:numeric"`
	BaseQuantity      float64 `gorm:"-"`
	UnitPriceBase     float64 `gorm:"-"`
}

func (FinanceInvoiceItem) TableName() string {
	return "finance_invoice_items"
}

type VatInventoryLedger struct {
	ID                int64     `gorm:"primaryKey;autoIncrement"`
	ProductID         int64     `gorm:"type:bigint"`
	VatRate           float64   `gorm:"type:numeric"`
	QuantityBalance   float64   `gorm:"type:numeric"`
	TotalValueBalance float64   `gorm:"type:numeric"`
	UpdatedAt         time.Time `gorm:"type:timestamp"`
}

func (VatInventoryLedger) TableName() string {
	return "vat_inventory_ledger"
}

type ProductUnit struct {
	ID             int64   `gorm:"primaryKey"`
	ProductID      int64   `gorm:"type:bigint"`
	UnitName       string  `gorm:"type:text"`
	ConversionRate float64 `gorm:"type:numeric"`
}

func (ProductUnit) TableName() string {
	return "product_units"
}
