package services

import (
	"context"
	"errors"
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/repository/postgres"
	"gorm.io/gorm"
)

type FinanceService interface {
	CreateTransaction(ctx context.Context, tx *gorm.DB, req domain.CreateTransactionRequest, userID string) error
	AllocateVATInvoice(ctx context.Context, tx *gorm.DB, req domain.VATAllocationRequest) ([]domain.OrderItem, error)
	GetPendingCODReports(ctx context.Context, db *gorm.DB) ([]domain.CODPendingReport, error)
	ConfirmCODDeposit(ctx context.Context, tx *gorm.DB, shipperID string, transactionIDs []int64) error
}

type financeService struct {
	repo postgres.FinanceRepository
}

func NewFinanceService(repo postgres.FinanceRepository) FinanceService {
	return &financeService{repo: repo}
}

func (s *financeService) CreateTransaction(ctx context.Context, tx *gorm.DB, req domain.CreateTransactionRequest, userID string) error {
	// Rule 1: Chặn thanh toán VAT tiền mặt nếu quá hạn mức
	if req.RefType == "INVOICE" {
		thresholdStr := os.Getenv("VAT_BANK_TRANSFER_THRESHOLD")
		if thresholdStr == "" {
			thresholdStr = "5000000" // Default 5.000.000 VNĐ
		}
		threshold, _ := strconv.ParseFloat(thresholdStr, 64)

		if req.Amount >= threshold {
			fundType, err := s.repo.GetFundAccountType(ctx, tx, req.FundAccountID)
			if err != nil {
				return fmt.Errorf("không thể xác định loại tài khoản quỹ: %v", err)
			}
			if fundType != "bank" {
				return fmt.Errorf("giao dịch hóa đơn trên %s phải thanh toán qua ngân hàng (chuyển khoản)", thresholdStr)
			}
		}

		// Rule 2: Logic chẻ phiếu
		invID, _ := strconv.ParseInt(req.RefID, 10, 64)
		invoice, err := s.repo.GetInvoiceByID(ctx, tx, invID)
		if err != nil {
			return fmt.Errorf("hóa đơn không tồn tại: %v", err)
		}

		remainingAmount := invoice.TotalAmountPostTax - invoice.PaidAmount
		var mainAmount, subAmount float64

		if req.Amount > remainingAmount {
			mainAmount = remainingAmount
			subAmount = req.Amount - remainingAmount
		} else {
			mainAmount = req.Amount
			subAmount = 0
		}

		// Tạo phiếu chính
		transMain := &domain.FinanceTransaction{
			Code:          fmt.Sprintf("TX-%d", time.Now().UnixNano()),
			Flow:          req.Flow,
			Amount:        mainAmount,
			FundAccountID: req.FundAccountID,
			RefType:       req.RefType,
			RefID:         req.RefID,
			Description:   "Thanh toán hóa đơn chính",
			Status:        "completed",
		}
		if err := s.repo.CreateTransaction(ctx, tx, transMain); err != nil {
			return err
		}

		// Tạo phiếu phụ nếu có chênh lệch
		if subAmount > 0 {
			transSub := &domain.FinanceTransaction{
				Code:          fmt.Sprintf("TX-SUB-%d", time.Now().UnixNano()),
				Flow:          req.Flow,
				Amount:        subAmount,
				FundAccountID: req.FundAccountID,
				RefType:       "OVERPAYMENT",
				RefID:         req.RefID,
				Description:   "Tiền thừa/chênh lệch thanh toán",
				Status:        "completed",
			}
			if err := s.repo.CreateTransaction(ctx, tx, transSub); err != nil {
				return err
			}
		}

		// Cập nhật trạng thái Hóa đơn
		newPaid := invoice.PaidAmount + mainAmount
		status := "PARTIAL"
		if newPaid >= invoice.TotalAmountPostTax {
			status = "PAID"
		}
		if err := s.repo.UpdateInvoicePaidAmount(ctx, tx, invoice.ID, newPaid, status); err != nil {
			return err
		}
	} else {
		// Non-Invoice transactions
		trans := &domain.FinanceTransaction{
			Code:          fmt.Sprintf("TX-GEN-%d", time.Now().UnixNano()),
			Flow:          req.Flow,
			Amount:        req.Amount,
			FundAccountID: req.FundAccountID,
			RefType:       req.RefType,
			RefID:         req.RefID,
			Description:   req.Description,
			Status:        "completed",
		}
		if err := s.repo.CreateTransaction(ctx, tx, trans); err != nil {
			return err
		}
	}

	return nil
}

// AllocateVATInvoice implements Knapsack DP for optimal item matching
func (s *financeService) AllocateVATInvoice(ctx context.Context, tx *gorm.DB, req domain.VATAllocationRequest) ([]domain.OrderItem, error) {
	items, err := s.repo.GetUnbilledOrderItems(ctx, tx, req.CustomerID)
	if err != nil {
		return nil, fmt.Errorf("lỗi lấy danh sách hàng chưa xuất hóa đơn: %v", err)
	}

	if len(items) == 0 {
		return nil, errors.New("khách hàng không có mặt hàng nào chưa xuất hóa đơn")
	}

	// Chuyển đổi sang Integer để tránh sai số thập phân (nhân với 1000 nếu cần)
	// Để đơn giản thuật toán, ta sẽ làm tròn số tiền thành số nguyên
	target := int(req.TargetAmount)
	n := len(items)

	// dp[i][w] = giá trị lớn nhất đạt được (<= w) khi chọn trong i item đầu
	dp := make([][]int, n+1)
	for i := range dp {
		dp[i] = make([]int, target+1)
	}

	for i := 1; i <= n; i++ {
		itemVal := int(items[i-1].TotalPrice)
		for w := 1; w <= target; w++ {
			if itemVal <= w {
				opt1 := dp[i-1][w]
				opt2 := dp[i-1][w-itemVal] + itemVal
				if opt1 > opt2 {
					dp[i][w] = opt1
				} else {
					dp[i][w] = opt2
				}
			} else {
				dp[i][w] = dp[i-1][w]
			}
		}
	}

	// Truy ngược tìm tập hợp items được chọn
	var selected []domain.OrderItem
	w := target
	for i := n; i > 0 && w > 0; i-- {
		if dp[i][w] != dp[i-1][w] {
			selected = append(selected, items[i-1])
			w -= int(items[i-1].TotalPrice)
		}
	}

	return selected, nil
}

func (s *financeService) GetPendingCODReports(ctx context.Context, db *gorm.DB) ([]domain.CODPendingReport, error) {
	var results []domain.CODPendingReport

	// Query to group by created_by
	// In GORM, doing a complex group by with struct loading is tricky, we can do a raw query or manual grouping
	var transactions []domain.FinanceTransaction
	if err := db.WithContext(ctx).Where("status = ? AND flow = ?", "pending", "in").Find(&transactions).Error; err != nil {
		return nil, err
	}

	mapReports := make(map[string]*domain.CODPendingReport)
	for _, tx := range transactions {
		shipperID := tx.CreatedBy
		if shipperID == "" {
			continue // ignore if no shipper
		}
		if _, exists := mapReports[shipperID]; !exists {
			mapReports[shipperID] = &domain.CODPendingReport{
				ShipperID:    shipperID,
				TotalAmount:  0,
				Transactions: []domain.FinanceTransaction{},
			}
		}
		mapReports[shipperID].Transactions = append(mapReports[shipperID].Transactions, tx)
		mapReports[shipperID].TotalAmount += tx.Amount
	}

	for _, v := range mapReports {
		results = append(results, *v)
	}

	return results, nil
}

func (s *financeService) ConfirmCODDeposit(ctx context.Context, tx *gorm.DB, shipperID string, transactionIDs []int64) error {
	if len(transactionIDs) == 0 {
		return errors.New("không có giao dịch nào để xác nhận")
	}

	// Update transactions to completed
	res := tx.WithContext(ctx).Model(&domain.FinanceTransaction{}).
		Where("id IN ? AND status = ? AND flow = ? AND created_by = ?", transactionIDs, "pending", "in", shipperID).
		Update("status", "completed")

	if res.Error != nil {
		return res.Error
	}
	if res.RowsAffected == 0 {
		return errors.New("không có giao dịch nào được xác nhận (có thể đã được xác nhận hoặc sai shipper)")
	}

	return nil
}
