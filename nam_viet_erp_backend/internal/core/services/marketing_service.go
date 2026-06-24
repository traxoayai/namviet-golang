package services

import (
	"context"
	"encoding/json"

	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/repository/postgres"
	"gorm.io/gorm"
)

type MarketingService interface {
	CreateCampaign(ctx context.Context, tx *gorm.DB, campaign *domain.MarketingCampaign) error
	StartCampaign(ctx context.Context, tx *gorm.DB, campaignID int64) error
	GetMetrics(ctx context.Context, tx *gorm.DB, campaignID int64) (*domain.MarketingCampaignMetric, error)
	CreateSurvey(ctx context.Context, tx *gorm.DB, survey *domain.MarketingSurvey) error
	GetSurveys(ctx context.Context, tx *gorm.DB) ([]domain.MarketingSurvey, error)
}

type marketingService struct {
	mktRepo postgres.MarketingRepository
	jobRepo postgres.JobRepository
}

func NewMarketingService(mktRepo postgres.MarketingRepository, jobRepo postgres.JobRepository) MarketingService {
	return &marketingService{
		mktRepo: mktRepo,
		jobRepo: jobRepo,
	}
}

func (s *marketingService) CreateCampaign(ctx context.Context, tx *gorm.DB, campaign *domain.MarketingCampaign) error {
	return s.mktRepo.CreateCampaign(ctx, tx, campaign)
}

func (s *marketingService) StartCampaign(ctx context.Context, tx *gorm.DB, campaignID int64) error {
	_, err := s.mktRepo.GetCampaign(ctx, tx, campaignID)
	if err != nil {
		return err
	}

	// Update status
	if err := s.mktRepo.UpdateCampaignStatus(ctx, tx, campaignID, "running"); err != nil {
		return err
	}

	// Publish Mock Jobs based on Flow Config (Simplification for Demo)
	// In a real scenario, this parses the FlowConfig JSON and constructs the DAG of jobs.
	
	// Create a Zalo ZNS job
	payload1, _ := json.Marshal(map[string]interface{}{
		"campaign_id": campaignID,
		"phone":       "0909123456",
	})
	s.jobRepo.Enqueue(ctx, tx, &domain.Job{
		JobType: "zalo_zns",
		Payload: string(payload1),
	})

	// Create a Zalo OA job
	payload2, _ := json.Marshal(map[string]interface{}{
		"campaign_id": campaignID,
		"zalo_id":     "8482934020",
	})
	s.jobRepo.Enqueue(ctx, tx, &domain.Job{
		JobType: "zalo_oa",
		Payload: string(payload2),
	})

	// Create a Voucher job
	payload3, _ := json.Marshal(map[string]interface{}{
		"campaign_id":   campaignID,
		"user_id":       10,
		"voucher_value": 50000.0,
	})
	s.jobRepo.Enqueue(ctx, tx, &domain.Job{
		JobType: "voucher",
		Payload: string(payload3),
	})

	return nil
}

func (s *marketingService) GetMetrics(ctx context.Context, tx *gorm.DB, campaignID int64) (*domain.MarketingCampaignMetric, error) {
	return s.mktRepo.GetMetrics(ctx, tx, campaignID)
}

func (s *marketingService) CreateSurvey(ctx context.Context, tx *gorm.DB, survey *domain.MarketingSurvey) error {
	return s.mktRepo.CreateSurvey(ctx, tx, survey)
}

func (s *marketingService) GetSurveys(ctx context.Context, tx *gorm.DB) ([]domain.MarketingSurvey, error) {
	return s.mktRepo.GetSurveys(ctx, tx)
}
