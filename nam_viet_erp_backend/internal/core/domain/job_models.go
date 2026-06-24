package domain

import (
	"time"
)

type Job struct {
	ID        int64     `json:"id" gorm:"column:id;primaryKey"`
	JobType   string    `json:"job_type" gorm:"column:job_type"`
	Payload   string    `json:"payload" gorm:"column:payload;type:jsonb"`
	Status    string    `json:"status" gorm:"column:status"` // pending, processing, completed, failed
	RunAt     time.Time `json:"run_at" gorm:"column:run_at"`
	CreatedAt time.Time `json:"created_at" gorm:"column:created_at"`
	UpdatedAt time.Time `json:"updated_at" gorm:"column:updated_at"`
}

func (Job) TableName() string {
	return "jobs"
}
