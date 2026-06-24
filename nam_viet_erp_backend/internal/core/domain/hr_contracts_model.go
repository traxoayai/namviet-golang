package domain

import (
	"time"
)

type HRContract struct {
	ID           int64     `json:"id" gorm:"column:id;primaryKey"`
	UserID       string    `json:"user_id" gorm:"column:user_id"`
	ContractType string    `json:"contract_type" gorm:"column:contract_type"`
	BaseSalary   float64   `json:"base_salary" gorm:"column:base_salary"`
	StartDate    string    `json:"start_date" gorm:"column:start_date"` // date
	EndDate      *string   `json:"end_date" gorm:"column:end_date"`     // null-able
	KpiTarget    string    `json:"kpi_target" gorm:"column:kpi_target"`
	Status       string    `json:"status" gorm:"column:status"`
	CreatedAt    time.Time `json:"created_at" gorm:"column:created_at"`
	UpdatedAt    time.Time `json:"updated_at" gorm:"column:updated_at"`
}

func (HRContract) TableName() string {
	return "hr_contracts"
}
