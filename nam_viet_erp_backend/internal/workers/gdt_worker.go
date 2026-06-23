package workers

import (
	"log"
	"math/rand"
	"time"

	"github.com/namvieterp/backend/internal/core/services"
	"github.com/robfig/cron/v3"
	"gorm.io/gorm"
)

type GdtWorker struct {
	cron           *cron.Cron
	gdtService     *services.GdtService
	invoiceService *services.InvoiceService
	db             *gorm.DB
}

func NewGdtWorker(db *gorm.DB, gdtService *services.GdtService, invoiceService *services.InvoiceService) *GdtWorker {
	c := cron.New(cron.WithLocation(time.FixedZone("UTC+7", 7*60*60))) // Vietnam time
	return &GdtWorker{
		cron:           c,
		gdtService:     gdtService,
		invoiceService: invoiceService,
		db:             db,
	}
}

func (w *GdtWorker) Start() {
	// Run every 2 hours at minute 0 (0 */2 * * *)
	_, err := w.cron.AddFunc("0 */2 * * *", func() {
		w.SyncRoutine()
	})
	if err != nil {
		log.Printf("Error scheduling GDT cron: %v", err)
		return
	}
	w.cron.Start()
	log.Println("GDT Sync Worker started (Every 2 hours)")
}

func (w *GdtWorker) Stop() {
	w.cron.Stop()
}

// SyncRoutine forces a sync for both inbound and outbound
func (w *GdtWorker) SyncRoutine() {
	token, err := w.gdtService.GetActiveToken()
	if err != nil {
		log.Printf("GDT Sync Worker skip: %v", err)
		return
	}

	log.Println("GDT Sync Worker: Fetching invoices...")
	
	// Fetch for today
	now := time.Now()
	// Fetch last 3 days
	startDate := now.AddDate(0, 0, -3).Format("02/01/2006")
	endDate := now.Format("02/01/2006")

	// 1. Fetch Inbound (Mua vao)
	inboundList, err := w.gdtService.FetchList(token, startDate, endDate, false)
	if err == nil && len(inboundList) > 0 {
		w.processList(token, inboundList, "inbound")
	}

	// 2. Fetch Outbound (Ban ra)
	outboundList, err := w.gdtService.FetchList(token, startDate, endDate, true)
	if err == nil && len(outboundList) > 0 {
		w.processList(token, outboundList, "outbound")
	}
}

func (w *GdtWorker) processList(token string, list []interface{}, direction string) {
	var invoicesToSync []map[string]interface{}

	for i, item := range list {
		invMap, ok := item.(map[string]interface{})
		if !ok {
			continue
		}

		shdon, _ := invMap["shdon"].(string)
		khhdon, _ := invMap["khhdon"].(string)
		
		var count int64
		w.db.Table("finance_invoices").
			Where("invoice_number = ? AND invoice_symbol = ? AND direction = ?", shdon, khhdon, direction).
			Count(&count)
		
		if count > 0 {
			continue // Already synced
		}

		nbmst, _ := invMap["nbmst"].(string)
		khmshdon, _ := invMap["khmshdon"].(string)

		// Sleep to avoid 429 WAF (Random 10s to 20s)
		sleepSecs := rand.Intn(11) + 10
		time.Sleep(time.Duration(sleepSecs) * time.Second)

		detail, err := w.gdtService.FetchDetail(token, nbmst, khhdon, shdon, khmshdon)
		if err != nil {
			log.Printf("Failed to fetch detail for %s: %v", shdon, err)
			continue
		}

		// Merge detail into invMap
		if hdhhList, ok := detail["hdhhdvu"].([]interface{}); ok {
			invMap["hdhhdvu"] = hdhhList
		} else {
			invMap["hdhhdvu"] = []interface{}{}
		}
		invMap["invoice_source"] = "gdt_" + direction

		invoicesToSync = append(invoicesToSync, invMap)
		
		// Bulk process every 50 invoices
		if len(invoicesToSync) >= 50 || i == len(list)-1 {
			w.invoiceService.SyncGdtInvoices(invoicesToSync)
			invoicesToSync = []map[string]interface{}{} // reset
		}
	}
}
