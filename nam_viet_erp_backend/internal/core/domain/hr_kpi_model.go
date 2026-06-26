package domain

import (
	"time"
)

// HRKPIMetric - Từ điển các chỉ số KPI
type HRKPIMetric struct {
	Code        string    `json:"code" gorm:"column:code;primaryKey"`
	Name        string    `json:"name" gorm:"column:name"`
	Description string    `json:"description" gorm:"column:description"`
	QuerySource string    `json:"query_source" gorm:"column:query_source"`
	IsActive    bool      `json:"is_active" gorm:"column:is_active"`
	CreatedAt   time.Time `json:"created_at" gorm:"column:created_at"`
}

func (HRKPIMetric) TableName() string {
	return "hr_kpi_metrics"
}

// HRKPITarget - Bảng giao chỉ tiêu KPI cho nhân viên
type HRKPITarget struct {
	ID          int64     `json:"id" gorm:"column:id;primaryKey;autoIncrement"`
	EmployeeID  string    `json:"employee_id" gorm:"column:employee_id"`
	Month       int       `json:"month" gorm:"column:month"`
	Year        int       `json:"year" gorm:"column:year"`
	MetricCode  string    `json:"metric_code" gorm:"column:metric_code"`
	TargetValue float64   `json:"target_value" gorm:"column:target_value"`
	AssignedBy  *string   `json:"assigned_by" gorm:"column:assigned_by"`
	CreatedAt   time.Time `json:"created_at" gorm:"column:created_at"`
	UpdatedAt   time.Time `json:"updated_at" gorm:"column:updated_at"`
}

func (HRKPITarget) TableName() string {
	return "hr_kpi_targets"
}

// HRKPIRewardRule - Luật trả thưởng tương ứng với các chỉ số KPI
type HRKPIRewardRule struct {
	ID            int64     `json:"id" gorm:"column:id;primaryKey;autoIncrement"`
	MetricCode    string    `json:"metric_code" gorm:"column:metric_code"`
	ConditionType string    `json:"condition_type" gorm:"column:condition_type"` // '>=', '<=', '=='
	RewardType    string    `json:"reward_type" gorm:"column:reward_type"`       // 'PERCENTAGE', 'FIXED'
	RewardValue   float64   `json:"reward_value" gorm:"column:reward_value"`
	CreatedAt     time.Time `json:"created_at" gorm:"column:created_at"`
	UpdatedAt     time.Time `json:"updated_at" gorm:"column:updated_at"`
}

func (HRKPIRewardRule) TableName() string {
	return "hr_kpi_reward_rules"
}

// AssignKPITargetRequest represents the incoming payload to assign a target
type AssignKPITargetRequest struct {
	EmployeeID  string  `json:"employee_id" binding:"required"`
	Month       int     `json:"month" binding:"required"`
	Year        int     `json:"year" binding:"required"`
	MetricCode  string  `json:"metric_code" binding:"required"`
	TargetValue float64 `json:"target_value" binding:"required"`
}

// KPIProgressDetail represents the progress of a specific KPI
type KPIProgressDetail struct {
	MetricCode  string  `json:"metric_code"`
	MetricName  string  `json:"metric_name"`
	TargetValue float64 `json:"target_value"`
	ActualValue float64 `json:"actual_value"`
	IsAchieved  bool    `json:"is_achieved"`
	Percentage  float64 `json:"percentage"`
}

// KPIProgressResponse represents the response for the progress API
type KPIProgressResponse struct {
	Month       int                 `json:"month"`
	Year        int                 `json:"year"`
	EmployeeID  string              `json:"employee_id"`
	Progresses  []KPIProgressDetail `json:"progresses"`
}
