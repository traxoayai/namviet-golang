package domain

import (
	"time"
)

type HRAttendance struct {
	ID                 int64      `json:"id" gorm:"column:id;primaryKey"`
	ShiftID            int64      `json:"shift_id" gorm:"column:shift_id"`
	UserID             string     `json:"user_id" gorm:"column:user_id"`
	CheckInTime        *time.Time `json:"check_in_time" gorm:"column:check_in_time"`
	CheckInIp          string     `json:"check_in_ip" gorm:"column:check_in_ip"`
	CheckInLat         float64    `json:"check_in_lat" gorm:"column:check_in_lat"`
	CheckInLng         float64    `json:"check_in_lng" gorm:"column:check_in_lng"`
	DistanceFromBranch float64    `json:"distance_from_branch" gorm:"column:distance_from_branch"`
	IsValidLocation    bool       `json:"is_valid_location" gorm:"column:is_valid_location"`
	CheckOutTime       *time.Time `json:"check_out_time" gorm:"column:check_out_time"`
	CheckOutIp         string     `json:"check_out_ip" gorm:"column:check_out_ip"`
	CheckOutLat        float64    `json:"check_out_lat" gorm:"column:check_out_lat"`
	CheckOutLng        float64    `json:"check_out_lng" gorm:"column:check_out_lng"`
	CreatedAt          time.Time  `json:"created_at" gorm:"column:created_at"`
	UpdatedAt          time.Time  `json:"updated_at" gorm:"column:updated_at"`
}

func (HRAttendance) TableName() string {
	return "hr_attendances"
}

type HRCheckInRequest struct {
	ShiftID int64   `json:"shift_id" binding:"required"`
	Lat     float64 `json:"lat" binding:"required"`
	Lng     float64 `json:"lng" binding:"required"`
}

type HRCheckInResponse struct {
	Message          string  `json:"message"`
	Distance         float64 `json:"distance"`
	IsValid          bool    `json:"is_valid"`
}
