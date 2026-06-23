package services

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/namvieterp/backend/internal/core/domain"
	"gorm.io/gorm"
)

func (s *InvoiceService) SyncGdtInvoices(payloads []map[string]interface{}) (int, error) {
	syncedCount := 0

	err := s.db.Transaction(func(tx *gorm.DB) error {
		for _, invMap := range payloads {
			// Extract header
			headerMap, ok := invMap["header"].(map[string]interface{})
			if !ok {
				continue
			}

			direction, _ := invMap["direction"].(string)
			if direction == "" {
				direction = "inbound"
			}

			invoiceNum := fmt.Sprintf("%v", headerMap["invoice_number"])
			invoiceSymbol := fmt.Sprintf("%v", headerMap["invoice_symbol"])
			supplierTaxCode := fmt.Sprintf("%v", headerMap["supplier_tax_code"])
			buyerTaxCode := fmt.Sprintf("%v", headerMap["buyer_tax_code"])

			invoiceDateStr, _ := headerMap["invoice_date"].(string)
			var invoiceDate time.Time
			if invoiceDateStr != "" {
				t, err := time.Parse("2006-01-02", invoiceDateStr)
				if err == nil {
					invoiceDate = t
				}
			}

			totalPreTax, _ := headerMap["total_amount_pre_tax"].(float64)
			totalTax, _ := headerMap["total_tax"].(float64)
			totalPostTax, _ := headerMap["total_amount_post_tax"].(float64)
			supplierName, _ := headerMap["supplier_name"].(string)
			buyerName, _ := headerMap["buyer_name"].(string)

			rawBytes, _ := json.Marshal(invMap)
			var rawJson interface{}
			json.Unmarshal(rawBytes, &rawJson)
			
			itemsBytes, _ := json.Marshal(invMap["items"])
			var itemsJson interface{}
			json.Unmarshal(itemsBytes, &itemsJson)

			if direction == "inbound" {
				var count int64
				tx.Model(&domain.FinanceInvoice{}).
					Where("invoice_number = ? AND invoice_symbol = ? AND supplier_tax_code = ? AND direction = 'inbound'", 
						invoiceNum, invoiceSymbol, supplierTaxCode).
					Count(&count)

				if count == 0 {
					newInv := domain.FinanceInvoice{
						InvoiceNumber:      invoiceNum,
						InvoiceSymbol:      invoiceSymbol,
						InvoiceDate:        invoiceDate,
						SupplierNameRaw:    supplierName,
						SupplierTaxCode:    supplierTaxCode,
						BuyerTaxCode:       buyerTaxCode,
						TotalAmountPreTax:  totalPreTax,
						TaxAmount:          totalTax,
						TotalAmountPostTax: totalPostTax,
						ParsedData:         rawJson,
						ItemsJSON:          itemsJson,
						Status:             "draft",
						Direction:          "inbound",
					}
					
					if err := tx.Create(&newInv).Error; err != nil {
						return err
					}
					
					// Insert items
					if itemsArray, ok := invMap["items"].([]interface{}); ok {
						for _, itemIntf := range itemsArray {
							if itemMap, ok := itemIntf.(map[string]interface{}); ok {
								name, _ := itemMap["name"].(string)
								unit, _ := itemMap["unit"].(string)
								qty, _ := itemMap["quantity"].(float64)
								price, _ := itemMap["unit_price"].(float64)
								totalAmt, _ := itemMap["total"].(float64)
								vatRate, _ := itemMap["vat_rate"].(float64)
								
								invItem := domain.FinanceInvoiceItem{
									InvoiceID:           newInv.ID,
									VendorProductName:   name,
									VendorUnit:          unit,
									Quantity:            qty,
									PreVatPrice:         price,
									VatRate:             vatRate,
									TotalAmountPreVat:   totalAmt,
									// We don't have supplier_sku in the domain model directly, so ignore
								}
								tx.Create(&invItem)
							}
						}
					}
					syncedCount++
				}
			} else {
				// Outbound
				var count int64
				tx.Model(&domain.FinanceInvoice{}).
					Where("invoice_number = ? AND invoice_symbol = ? AND direction = 'outbound'", 
						invoiceNum, invoiceSymbol).
					Count(&count)

				if count == 0 {
					newInv := domain.FinanceInvoice{
						InvoiceNumber:      invoiceNum,
						InvoiceSymbol:      invoiceSymbol,
						InvoiceDate:        invoiceDate,
						BuyerName:          buyerName,
						BuyerTaxCode:       buyerTaxCode,
						SupplierTaxCode:    supplierTaxCode,
						TotalAmountPreTax:  totalPreTax,
						TaxAmount:          totalTax,
						TotalAmountPostTax: totalPostTax,
						ParsedData:         rawJson,
						ItemsJSON:          itemsJson,
						Status:             "issued_outbound", // Assume it's issued if from GDT
						Direction:          "outbound",
					}
					
					if err := tx.Create(&newInv).Error; err != nil {
						return err
					}

					// Insert items and Deduct VAT Inventory
					if itemsArray, ok := invMap["items"].([]interface{}); ok {
						for _, itemIntf := range itemsArray {
							if itemMap, ok := itemIntf.(map[string]interface{}); ok {
								name, _ := itemMap["name"].(string)
								sku, _ := itemMap["supplier_sku"].(string)
								unit, _ := itemMap["unit"].(string)
								qty, _ := itemMap["quantity"].(float64)
								price, _ := itemMap["unit_price"].(float64)
								totalAmt, _ := itemMap["total"].(float64)
								vatRate, _ := itemMap["vat_rate"].(float64)
								
								invItem := domain.FinanceInvoiceItem{
									InvoiceID:           newInv.ID,
									VendorProductName:   name,
									VendorUnit:          unit,
									Quantity:            qty,
									PreVatPrice:         price,
									VatRate:             vatRate,
									TotalAmountPreVat:   totalAmt,
								}
								tx.Create(&invItem)

								// Look up product id by sku
								if sku != "" {
									var p struct {
										ID int64
									}
									if err := tx.Table("products").Select("id").Where("barcode = ?", sku).First(&p).Error; err == nil {
										invItem.ProductID = &p.ID
										
										// Deduct VAT Inventory directly
										var ledger domain.VatInventoryLedger
										err = tx.Where("product_id = ? AND vat_rate = ?", p.ID, vatRate).First(&ledger).Error
										if err == nil {
											// Has ledger, deduct
											ledger.QuantityBalance -= qty
											ledger.TotalValueBalance -= totalAmt
											tx.Save(&ledger)
										} else {
											// For outbound, if no ledger exists, it will go negative
											ledger = domain.VatInventoryLedger{
												ProductID:         p.ID,
												VatRate:           vatRate,
												QuantityBalance:   -qty,
												TotalValueBalance: -totalAmt,
												UpdatedAt:         time.Now(),
											}
											tx.Create(&ledger)
										}
									}
								}
							}
						}
					}
					syncedCount++
				}
			}
		}
		return nil
	})

	return syncedCount, err
}
