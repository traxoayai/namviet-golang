package domain

import "time"

type MarketingCampaign struct {
	ID         int64   `json:"id" gorm:"column:id;primaryKey"`
	Name       string  `json:"name" gorm:"column:name"`
	Budget     float64 `json:"budget" gorm:"column:budget"`
	Spent      float64 `json:"spent" gorm:"column:spent"`
	FlowConfig string  `json:"flow_config" gorm:"column:flow_config;type:jsonb"`
	Status     string  `json:"status" gorm:"column:status"`
	CreatedAt  time.Time `json:"created_at" gorm:"column:created_at"`
	UpdatedAt  time.Time `json:"updated_at" gorm:"column:updated_at"`
}

func (MarketingCampaign) TableName() string {
	return "marketing_campaigns"
}

type MarketingCampaignMetric struct {
	ID            int64 `json:"id" gorm:"column:id;primaryKey"`
	CampaignID    int64 `json:"campaign_id" gorm:"column:campaign_id"`
	SentCount     int   `json:"sent_count" gorm:"column:sent_count"`
	OpenCount     int   `json:"open_count" gorm:"column:open_count"`
	ClickedCount  int   `json:"clicked_count" gorm:"column:clicked_count"`
	RedeemedCount int   `json:"redeemed_count" gorm:"column:redeemed_count"`
	CreatedAt     time.Time `json:"created_at" gorm:"column:created_at"`
	UpdatedAt     time.Time `json:"updated_at" gorm:"column:updated_at"`
}

func (MarketingCampaignMetric) TableName() string {
	return "marketing_campaign_metrics"
}

type MarketingSurvey struct {
	ID         int64   `json:"id" gorm:"column:id;primaryKey"`
	Name       string  `json:"name" gorm:"column:name"`
	FormConfig string  `json:"form_config" gorm:"column:form_config;type:jsonb"`
	CreatedAt  time.Time `json:"created_at" gorm:"column:created_at"`
	UpdatedAt  time.Time `json:"updated_at" gorm:"column:updated_at"`
}

func (MarketingSurvey) TableName() string {
	return "marketing_surveys"
}
