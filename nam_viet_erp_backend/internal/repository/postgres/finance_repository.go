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
