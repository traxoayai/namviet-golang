package postgres

import (
	"context"

	"github.com/namvieterp/backend/internal/core/domain"
	"gorm.io/gorm"
)

type MarketingRepository interface {
	CreateCampaign(ctx context.Context, tx *gorm.DB, campaign *domain.MarketingCampaign) error
	GetCampaign(ctx context.Context, tx *gorm.DB, campaignID int64) (*domain.MarketingCampaign, error)
	UpdateCampaignStatus(ctx context.Context, tx *gorm.DB, campaignID int64, status string) error
	UpdateCampaignSpent(ctx context.Context, tx *gorm.DB, campaignID int64, amount float64) error
	
	GetMetrics(ctx context.Context, tx *gorm.DB, campaignID int64) (*domain.MarketingCampaignMetric, error)
	IncrementMetric(ctx context.Context, tx *gorm.DB, campaignID int64, field string, amount int) error

	CreateSurvey(ctx context.Context, tx *gorm.DB, survey *domain.MarketingSurvey) error
	GetSurveys(ctx context.Context, tx *gorm.DB) ([]domain.MarketingSurvey, error)
}

type marketingRepository struct{}

func NewMarketingRepository() MarketingRepository {
	return &marketingRepository{}
}

func (r *marketingRepository) CreateCampaign(ctx context.Context, tx *gorm.DB, campaign *domain.MarketingCampaign) error {
	return tx.Create(campaign).Error
}

func (r *marketingRepository) GetCampaign(ctx context.Context, tx *gorm.DB, campaignID int64) (*domain.MarketingCampaign, error) {
	var c domain.MarketingCampaign
	err := tx.First(&c, campaignID).Error
	return &c, err
}

func (r *marketingRepository) UpdateCampaignStatus(ctx context.Context, tx *gorm.DB, campaignID int64, status string) error {
	return tx.Model(&domain.MarketingCampaign{}).Where("id = ?", campaignID).Update("status", status).Error
}

func (r *marketingRepository) UpdateCampaignSpent(ctx context.Context, tx *gorm.DB, campaignID int64, amount float64) error {
	return tx.Exec("UPDATE marketing_campaigns SET spent = spent + ? WHERE id = ?", amount, campaignID).Error
}

func (r *marketingRepository) GetMetrics(ctx context.Context, tx *gorm.DB, campaignID int64) (*domain.MarketingCampaignMetric, error) {
	var m domain.MarketingCampaignMetric
	err := tx.Where("campaign_id = ?", campaignID).FirstOrCreate(&m, domain.MarketingCampaignMetric{CampaignID: campaignID}).Error
	return &m, err
}

func (r *marketingRepository) IncrementMetric(ctx context.Context, tx *gorm.DB, campaignID int64, field string, amount int) error {
	// Ensure metrics record exists
	r.GetMetrics(ctx, tx, campaignID)
	// Safe increment
	return tx.Exec("UPDATE marketing_campaign_metrics SET "+field+" = "+field+" + ? WHERE campaign_id = ?", amount, campaignID).Error
}

func (r *marketingRepository) CreateSurvey(ctx context.Context, tx *gorm.DB, survey *domain.MarketingSurvey) error {
	return tx.Create(survey).Error
}

func (r *marketingRepository) GetSurveys(ctx context.Context, tx *gorm.DB) ([]domain.MarketingSurvey, error) {
	var s []domain.MarketingSurvey
	err := tx.Find(&s).Error
	return s, err
}
