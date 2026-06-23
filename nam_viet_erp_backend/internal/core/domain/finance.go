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
	CreatedAt       time.Time `json:"created_at"`
}

func (FinanceTransaction) TableName() string {
	return "finance_transactions"
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
