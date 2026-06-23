package services

import (
	"errors"
	"fmt"
	"math"
	"time"

	"github.com/namvieterp/backend/internal/core/domain"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type InvoiceService struct {
	db           *gorm.DB
	sepayService *SepayService
}

func NewInvoiceService(db *gorm.DB) *InvoiceService {
	return &InvoiceService{
		db:           db,
		sepayService: NewSepayService(),
	}
}

func (s *InvoiceService) UpsertAndVerify(payload *domain.InvoicePayload) (*domain.FinanceInvoice, error) {
	var savedInvoice domain.FinanceInvoice

	err := s.db.Transaction(func(tx *gorm.DB) error {
		// 1. Upsert FinanceInvoice
		invDate, _ := time.Parse("2006-01-02", payload.InvoiceDate)

		status := payload.Status
		if payload.IsDraft {
			status = "draft"
		} else if status == "" {
			if payload.Direction == "outbound" {
				status = "issued_outbound"
			} else {
				status = "verified"
			}
		}

		direction := payload.Direction
		if direction == "" {
			direction = "inbound"
		}

		savedInvoice = domain.FinanceInvoice{
			InvoiceNumber:         payload.InvoiceNumber,
			InvoiceSymbol:         payload.InvoiceSymbol,
			InvoiceDate:           invDate,
			SupplierID:            payload.SupplierID,
			SupplierNameRaw:       payload.SupplierNameRaw,
			SupplierTaxCode:       payload.SupplierTaxCode,
			BuyerName:             payload.BuyerName,
			BuyerTaxCode:          payload.BuyerTaxCode,
			BuyerAddress:          payload.BuyerAddress,
			BuyerEmail:            payload.BuyerEmail,
			OrderID:               payload.OrderID,
			Direction:             direction,
			FileURL:               payload.FileURL,
			FileType:              "xml",
			Status:                status,
			TotalAmountPreTax:     payload.TotalAmountPreTax,
			TaxAmount:             payload.TaxAmount,
			TotalAmountPostTax:    payload.TotalAmountPostTax,
			TotalPriceExcludesVat: payload.TotalPriceExcludesVat,
			TotalTradeDiscount:    payload.TotalTradeDiscount,
			TotalFeeAmount:        payload.TotalFeeAmount,
			ParsedData:            payload.ParsedData,
			ItemsJSON:             payload.ItemsData,
		}

		if payload.ID != nil && *payload.ID > 0 {
			var existing domain.FinanceInvoice
			if err := tx.First(&existing, *payload.ID).Error; err == nil {
				savedInvoice.SepayReferenceCode = existing.SepayReferenceCode
				savedInvoice.SepayTrackingCode = existing.SepayTrackingCode
				if savedInvoice.FileURL == "" {
					savedInvoice.FileURL = existing.FileURL
				}
			}

			savedInvoice.ID = *payload.ID
			if err := tx.Save(&savedInvoice).Error; err != nil {
				return err
			}
			// Delete old items
			if err := tx.Where("invoice_id = ?", savedInvoice.ID).Delete(&domain.FinanceInvoiceItem{}).Error; err != nil {
				return err
			}
		} else {
			if err := tx.Create(&savedInvoice).Error; err != nil {
				return err
			}
		}

		// 2. Process Items and Update VAT Inventory
		totalInvoiceFee := payload.TotalFeeAmount
		totalPriceExcludesVat := payload.TotalPriceExcludesVat

		for _, item := range payload.ItemsData {
			if item.ProductID == nil || *item.ProductID == 0 {
				return errors.New("item missing product_id")
			}

			var productUnit domain.ProductUnit
			var err error

			// Bug fix: use InternalProductUnitId if provided, else fallback to name
			if item.InternalProductUnitId != nil && *item.InternalProductUnitId > 0 {
				err = tx.First(&productUnit, *item.InternalProductUnitId).Error
			} else {
				err = tx.Where("product_id = ? AND lower(unit_name) = lower(?)", *item.ProductID, item.VendorUnit).First(&productUnit).Error
			}

			if err != nil {
				if errors.Is(err, gorm.ErrRecordNotFound) {
					return fmt.Errorf("không tìm thấy đơn vị '%s' cho SP #%d", item.VendorUnit, *item.ProductID)
				}
				return err
			}

			conversionRate := productUnit.ConversionRate
			if conversionRate == 0 {
				conversionRate = 1
			}

			qtyBase := item.Quantity * conversionRate

			// Calculate Proportional Fee
			var proportionalFee float64 = 0
			if totalPriceExcludesVat > 0 {
				proportionalFee = math.Round((item.TotalAmountPreVat/totalPriceExcludesVat)*totalInvoiceFee*100) / 100
			}

			totalValue := item.TotalAmountPreVat + proportionalFee
			unitPriceBase := 0.0
			if qtyBase > 0 {
				unitPriceBase = totalValue / qtyBase
			}

			// Resolve product_unit_id: prefer InternalProductUnitId, then ProductUnitID from payload
			resolvedUnitID := item.InternalProductUnitId
			if resolvedUnitID == nil && item.ProductUnitID != nil {
				resolvedUnitID = item.ProductUnitID
			}

			// Insert Invoice Item
			invItem := domain.FinanceInvoiceItem{
				InvoiceID:         savedInvoice.ID,
				ProductID:         item.ProductID,
				ProductUnitID:     resolvedUnitID,
				VendorProductName: item.ProductNameRaw,
				VendorUnit:        productUnit.UnitName,
				Quantity:          item.Quantity,
				QuantityBuyer:     item.QuantityBuyer,
				PreVatPrice:       item.UnitPrice,
				TotalAmountPreVat: item.TotalAmountPreVat,
				VatRate:           item.VatRate,
				DiscountAmount:    item.DiscountAmount,
				BaseQuantity:      qtyBase,
				UnitPriceBase:     unitPriceBase,
			}
			if err := tx.Create(&invItem).Error; err != nil {
				return err
			}

			// Upsert VAT Inventory Ledger ONLY if verified
			if savedInvoice.Status == "verified" || savedInvoice.Status == "verified_outbound" || savedInvoice.Status == "issued" {
				var ledger domain.VatInventoryLedger
				err = tx.Clauses(clause.Locking{Strength: "UPDATE"}).
					Where("product_id = ? AND vat_rate = ?", *item.ProductID, item.VatRate).
					First(&ledger).Error

				if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
					return err
				}

				if savedInvoice.Direction == "outbound" {
					if errors.Is(err, gorm.ErrRecordNotFound) {
						return fmt.Errorf("không có tồn kho VAT cho SP #%d để xuất", *item.ProductID)
					}
					if ledger.QuantityBalance < qtyBase {
						return fmt.Errorf("tồn kho VAT cho SP #%d không đủ (còn %.2f, cần xuất %.2f)", *item.ProductID, ledger.QuantityBalance, qtyBase)
					}
					ledger.QuantityBalance -= qtyBase
					ledger.TotalValueBalance -= totalValue
					ledger.UpdatedAt = time.Now()
					if err := tx.Save(&ledger).Error; err != nil {
						return err
					}
				} else {
					if errors.Is(err, gorm.ErrRecordNotFound) {
						ledger = domain.VatInventoryLedger{
							ProductID:         *item.ProductID,
							VatRate:           item.VatRate,
							QuantityBalance:   qtyBase,
							TotalValueBalance: totalValue,
							UpdatedAt:         time.Now(),
						}
						if err := tx.Create(&ledger).Error; err != nil {
							return err
						}
					} else {
						ledger.QuantityBalance += qtyBase
						ledger.TotalValueBalance += totalValue
						ledger.UpdatedAt = time.Now()
						if err := tx.Save(&ledger).Error; err != nil {
							return err
						}
					}
				}
			}
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	// SEPAY INTEGRATION (Synchronous)
	if savedInvoice.Direction == "outbound" {
		token, err := s.sepayService.GetToken()
		if err == nil && token != "" {
			var trackingCode, refCode string
			
			// If it's not a draft and already has a SepayReferenceCode, we just Issue it
			if !payload.IsDraft && savedInvoice.SepayReferenceCode != nil && *savedInvoice.SepayReferenceCode != "" {
				trackingCode, err = s.sepayService.IssueInvoice(*savedInvoice.SepayReferenceCode, token)
			} else {
				// Otherwise, Create it (either as a new Draft, or a new Issued invoice directly)
				refCode, trackingCode, err = s.sepayService.CreateInvoice(payload, token)
			}

			if err == nil && trackingCode != "" {
				// Check status to get PDF URL and Invoice Number
				sepayStatus, pdfUrl, realInvoiceNum, _ := s.sepayService.CheckStatus(trackingCode, token)
				
				// Update the DB
				updates := map[string]interface{}{}
				if refCode != "" {
					updates["sepay_reference_code"] = refCode
					savedInvoice.SepayReferenceCode = &refCode
				}
				if trackingCode != "" {
					updates["sepay_tracking_code"] = trackingCode
					savedInvoice.SepayTrackingCode = &trackingCode
				}
				if pdfUrl != "" {
					updates["file_url"] = pdfUrl
					savedInvoice.FileURL = pdfUrl
				}
				if realInvoiceNum != "" && realInvoiceNum != "0" {
					updates["invoice_number"] = realInvoiceNum
					savedInvoice.InvoiceNumber = realInvoiceNum
				}
				if sepayStatus == "success" || sepayStatus == "issued" {
					// ensure status is issued_outbound
					updates["status"] = "issued_outbound"
					savedInvoice.Status = "issued_outbound"
				} else if sepayStatus == "draft" {
					updates["status"] = "draft"
					savedInvoice.Status = "draft"
				}

				if len(updates) > 0 {
					s.db.Model(&domain.FinanceInvoice{}).Where("id = ?", savedInvoice.ID).Updates(updates)
				}
			} else {
				fmt.Printf("Sepay integration failed: %v\n", err)
			}
		} else {
			fmt.Printf("Failed to get Sepay token: %v\n", err)
		}
	}

	return &savedInvoice, nil
}
