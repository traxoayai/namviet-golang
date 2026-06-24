package domain

import "time"

// FinanceTransaction represents cash/bank flow
type FinanceTransaction struct {
	ID              int64     `json:"id" gorm:"primaryKey"`
	Code            string    `json:"code"`
	TransactionDate time.Time `json:"transaction_date"`
	Flow            string    `json:"flow"` // in, out
	Amount          float64   `json:"amount"`
	FundAccountID   int64     `json:"fund_account_id"`
	RefType         string    `json:"ref_type"`
	RefID           string    `json:"ref_id"`
	Description     string    `json:"description"`
	Status          string    `json:"status"` // pending, completed
	CreatedBy       string    `json:"created_by"`
	CreatedAt       time.Time `json:"created_at"`
}

func (FinanceTransaction) TableName() string {
	return "finance_transactions"
}

// FinanceTransactionAllocation represents an allocation to an order
type FinanceTransactionAllocation struct {
	ID              int64     `json:"id" gorm:"primaryKey;autoIncrement"`
	TransactionID   int64     `json:"transaction_id"`
	OrderID         string    `json:"order_id"`
	AllocatedAmount float64   `json:"allocated_amount"`
	CreatedAt       time.Time `json:"created_at"`
}

func (FinanceTransactionAllocation) TableName() string {
	return "finance_transaction_allocations"
}

// ChartOfAccount represents ledger accounts
type ChartOfAccount struct {
	ID          string `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	AccountCode string `json:"account_code"`
	Name        string `json:"name"`
	Type        string `json:"type"`
	BalanceType string `json:"balance_type"`
	Status      string `json:"status"`
}

func (ChartOfAccount) TableName() string {
	return "chart_of_accounts"
}

// CreateTransactionRequest payload
type CreateTransactionRequest struct {
	Flow          string  `json:"flow" binding:"required"`
	Amount        float64 `json:"amount" binding:"required,gt=0"`
	FundAccountID int64   `json:"fund_account_id" binding:"required"`
	RefType       string  `json:"ref_type"`
	RefID         string  `json:"ref_id"`
	Description   string  `json:"description"`
}

// VATAllocationRequest payload
type VATAllocationRequest struct {
	CustomerID   int64   `json:"customer_id" binding:"required"`
	TargetAmount float64 `json:"target_amount" binding:"required,gt=0"`
}

// CODPendingReport represents pending cod amount for a shipper
type CODPendingReport struct {
	ShipperID    string               `json:"shipper_id"`
	TotalAmount  float64              `json:"total_amount"`
	Transactions []FinanceTransaction `json:"transactions"`
}

// ConfirmCODDepositRequest payload
type ConfirmCODDepositRequest struct {
	ShipperUserID  string  `json:"shipper_user_id" binding:"required"`
	TransactionIDs []int64 `json:"transaction_ids" binding:"required,min=1"`
}
