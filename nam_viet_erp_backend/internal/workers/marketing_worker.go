package workers

import (
	"context"
	"encoding/json"
	"log"
	"time"

	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/repository/postgres"
	"gorm.io/gorm"
)

type MarketingWorker struct {
	db      *gorm.DB
	jobRepo postgres.JobRepository
	mktRepo postgres.MarketingRepository
}

func NewMarketingWorker(db *gorm.DB, jobRepo postgres.JobRepository, mktRepo postgres.MarketingRepository) *MarketingWorker {
	return &MarketingWorker{
		db:      db,
		jobRepo: jobRepo,
		mktRepo: mktRepo,
	}
}

func (w *MarketingWorker) Start(ctx context.Context) {
	log.Println("Starting Marketing Worker (Database Queue)...")
	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			log.Println("Marketing Worker stopped.")
			return
		case <-ticker.C:
			w.processJobs(ctx)
		}
	}
}

func (w *MarketingWorker) processJobs(ctx context.Context) {
	tx := w.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	jobs, err := w.jobRepo.FetchPendingJobs(ctx, tx, 10)
	if err != nil {
		tx.Rollback()
		log.Printf("Marketing Worker Error fetching jobs: %v\n", err)
		return
	}
	tx.Commit()

	if len(jobs) == 0 {
		return
	}

	for _, job := range jobs {
		err := w.handleJob(ctx, job)
		status := "completed"
		if err != nil {
			log.Printf("Marketing Worker Error processing job %d: %v\n", job.ID, err)
			status = "failed"
		}

		// Update job status in a new transaction
		txUpdate := w.db.Begin()
		w.jobRepo.UpdateJobStatus(ctx, txUpdate, job.ID, status)
		txUpdate.Commit()
	}
}

func (w *MarketingWorker) handleJob(ctx context.Context, job domain.Job) error {
	switch job.JobType {
	case "zalo_zns":
		return w.handleZaloZNS(ctx, job)
	case "zalo_oa":
		return w.handleZaloOA(ctx, job)
	case "delay":
		return w.handleDelay(ctx, job)
	case "voucher":
		return w.handleVoucher(ctx, job)
	default:
		log.Printf("Unknown job type: %s\n", job.JobType)
		return nil
	}
}

func (w *MarketingWorker) handleZaloZNS(ctx context.Context, job domain.Job) error {
	var payload map[string]interface{}
	json.Unmarshal([]byte(job.Payload), &payload)
	log.Printf("[ZALO_SENT] Mock sending ZNS to %v\n", payload["phone"])
	
	campaignID := int64(payload["campaign_id"].(float64))
	// Tăng số lượng sent
	tx := w.db.Begin()
	w.mktRepo.IncrementMetric(ctx, tx, campaignID, "sent_count", 1)
	tx.Commit()
	return nil
}

func (w *MarketingWorker) handleZaloOA(ctx context.Context, job domain.Job) error {
	var payload map[string]interface{}
	json.Unmarshal([]byte(job.Payload), &payload)
	log.Printf("[ZALO_SENT] Mock sending OA message to Zalo ID %v\n", payload["zalo_id"])
	
	campaignID := int64(payload["campaign_id"].(float64))
	// Tăng số lượng sent
	tx := w.db.Begin()
	w.mktRepo.IncrementMetric(ctx, tx, campaignID, "sent_count", 1)
	tx.Commit()
	return nil
}

func (w *MarketingWorker) handleDelay(ctx context.Context, job domain.Job) error {
	// A delay job might just spawn the next job in the flow
	// In this simple design, delay is handled by setting run_at in the next job
	return nil
}

func (w *MarketingWorker) handleVoucher(ctx context.Context, job domain.Job) error {
	var payload map[string]interface{}
	json.Unmarshal([]byte(job.Payload), &payload)
	campaignID := int64(payload["campaign_id"].(float64))
	voucherValue := payload["voucher_value"].(float64)

	tx := w.db.Begin()
	defer tx.Rollback()

	campaign, err := w.mktRepo.GetCampaign(ctx, tx, campaignID)
	if err != nil {
		return err
	}

	if campaign.Spent+voucherValue > campaign.Budget {
		log.Printf("[MARKETING] Campaign %d exceeded budget. Pausing campaign.\n", campaignID)
		w.mktRepo.UpdateCampaignStatus(ctx, tx, campaignID, "paused")
		tx.Commit()
		return nil // Still complete the job to not retry
	}

	// Update spent amount
	w.mktRepo.UpdateCampaignSpent(ctx, tx, campaignID, voucherValue)
	
	log.Printf("[VOUCHER_SENT] Mock sending voucher %v to user %v\n", voucherValue, payload["user_id"])
	tx.Commit()
	return nil
}
