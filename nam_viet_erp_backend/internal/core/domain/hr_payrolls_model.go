package domain

import (
	"time"
)

type HRPayroll struct {
	ID          int64     `json:"id" gorm:"column:id;primaryKey"`
	UserID      string    `json:"user_id" gorm:"column:user_id"`
	Month       int       `json:"month" gorm:"column:month"`
	Year        int       `json:"year" gorm:"column:year"`
	BaseSalary  float64   `json:"base_salary" gorm:"column:base_salary"`
	KpiBonus    float64   `json:"kpi_bonus" gorm:"column:kpi_bonus"`
	Commission  float64   `json:"commission" gorm:"column:commission"`
	TotalSalary float64   `json:"total_salary" gorm:"column:total_salary"`
	Status      string    `json:"status" gorm:"column:status"`
	CreatedAt   time.Time `json:"created_at" gorm:"column:created_at"`
	UpdatedAt   time.Time `json:"updated_at" gorm:"column:updated_at"`
}

func (HRPayroll) TableName() string {
	return "hr_payrolls"
}

type PayrollCalculateRequest struct {
	Month int `json:"month" binding:"required"`
	Year  int `json:"year" binding:"required"`
}
