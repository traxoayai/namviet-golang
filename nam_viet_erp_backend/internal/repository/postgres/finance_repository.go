package postgres

import (
	"context"

	"github.com/namvieterp/backend/internal/core/domain"
	"gorm.io/gorm"
)

type FinanceRepository interface {
	GetFundAccountType(ctx context.Context, tx *gorm.DB, fundAccountID int64) (string, error)
	CreateTransaction(ctx context.Context, tx *gorm.DB, trans *domain.FinanceTransaction) error
	GetInvoiceByID(ctx context.Context, tx *gorm.DB, invoiceID int64) (*domain.FinanceInvoice, error)
	UpdateInvoicePaidAmount(ctx context.Context, tx *gorm.DB, invoiceID int64, paidAmount float64, status string) error
	GetUnbilledOrderItems(ctx context.Context, tx *gorm.DB, customerID int64) ([]domain.OrderItem, error)

	GetTransactionByID(ctx context.Context, tx *gorm.DB, id int64) (*domain.FinanceTransaction, error)
	UpdateTransaction(ctx context.Context, tx *gorm.DB, trans *domain.FinanceTransaction) error
	UpdateFundAccountBalance(ctx context.Context, tx *gorm.DB, fundAccountID int64, amount float64, flow string) error
	UpdateOrderPaymentStatus(ctx context.Context, tx *gorm.DB, refType, orderID string) error
}

type financeRepository struct{}

func NewFinanceRepository() FinanceRepository {
	return &financeRepository{}
}

func (r *financeRepository) GetFundAccountType(ctx context.Context, tx *gorm.DB, fundAccountID int64) (string, error) {
	var fundType string
	err := tx.WithContext(ctx).Table("fund_accounts").Select("type").Where("id = ?", fundAccountID).Scan(&fundType).Error
	return fundType, err
}

func (r *financeRepository) CreateTransaction(ctx context.Context, tx *gorm.DB, trans *domain.FinanceTransaction) error {
	return tx.WithContext(ctx).Create(trans).Error
}

func (r *financeRepository) GetInvoiceByID(ctx context.Context, tx *gorm.DB, invoiceID int64) (*domain.FinanceInvoice, error) {
	var inv domain.FinanceInvoice
	err := tx.WithContext(ctx).Where("id = ?", invoiceID).First(&inv).Error
	return &inv, err
}

func (r *financeRepository) UpdateInvoicePaidAmount(ctx context.Context, tx *gorm.DB, invoiceID int64, paidAmount float64, status string) error {
	return tx.WithContext(ctx).Model(&domain.FinanceInvoice{}).Where("id = ?", invoiceID).Updates(map[string]interface{}{
		"paid_amount": paidAmount,
		"status":      status,
	}).Error
}

func (r *financeRepository) GetUnbilledOrderItems(ctx context.Context, tx *gorm.DB, customerID int64) ([]domain.OrderItem, error) {
	var items []domain.OrderItem
	// Giả lập lấy danh sách OrderItems chưa lên hóa đơn (invoice_id is null)
	err := tx.WithContext(ctx).
		Joins("JOIN orders ON orders.id = order_items.order_id").
		Where("orders.customer_id = ? AND order_items.id NOT IN (SELECT order_item_id FROM finance_invoice_items WHERE order_item_id IS NOT NULL)", customerID).
		Find(&items).Error
	return items, err
}

func (r *financeRepository) GetTransactionByID(ctx context.Context, tx *gorm.DB, id int64) (*domain.FinanceTransaction, error) {
	var trans domain.FinanceTransaction
	err := tx.WithContext(ctx).Where("id = ?", id).First(&trans).Error
	return &trans, err
}

func (r *financeRepository) UpdateTransaction(ctx context.Context, tx *gorm.DB, trans *domain.FinanceTransaction) error {
	return tx.WithContext(ctx).Save(trans).Error
}

func (r *financeRepository) UpdateFundAccountBalance(ctx context.Context, tx *gorm.DB, fundAccountID int64, amount float64, flow string) error {
	op := "+"
	if flow == "out" {
		op = "-"
	}
	return tx.WithContext(ctx).Exec("UPDATE fund_accounts SET balance = balance "+op+" ? WHERE id = ?", amount, fundAccountID).Error
}

func (r *financeRepository) UpdateOrderPaymentStatus(ctx context.Context, tx *gorm.DB, refType, orderID string) error {
	// refType expects ORDER or PURCHASE_ORDER
	if refType == "ORDER" {
		return tx.WithContext(ctx).Exec("UPDATE orders SET payment_status = 'paid' WHERE id = ?", orderID).Error
	} else if refType == "PURCHASE_ORDER" {
		return tx.WithContext(ctx).Exec("UPDATE purchase_orders SET payment_status = 'paid' WHERE id = ?", orderID).Error
	}
	return nil
}
