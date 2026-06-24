package domain

import (
	"time"
)

type HRWorkShift struct {
	ID        int64     `json:"id" gorm:"column:id;primaryKey"`
	UserID    string    `json:"user_id" gorm:"column:user_id"`
	ShiftName string    `json:"shift_name" gorm:"column:shift_name"`
	Date      string    `json:"date" gorm:"column:date"`
	StartTime string    `json:"start_time" gorm:"column:start_time"`
	EndTime   string    `json:"end_time" gorm:"column:end_time"`
	Status    string    `json:"status" gorm:"column:status"`
	CreatedAt time.Time `json:"created_at" gorm:"column:created_at"`
	UpdatedAt time.Time `json:"updated_at" gorm:"column:updated_at"`
}

func (HRWorkShift) TableName() string {
	return "hr_work_shifts"
}

type ShiftRegisterRequest struct {
	ShiftName string `json:"shift_name" binding:"required"`
	Date      string `json:"date" binding:"required"`
	StartTime string `json:"start_time" binding:"required"`
	EndTime   string `json:"end_time" binding:"required"`
}
