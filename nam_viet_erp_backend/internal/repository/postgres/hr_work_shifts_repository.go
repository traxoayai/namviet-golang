package postgres

import (
	"context"
	"github.com/namvieterp/backend/internal/core/domain"
	"gorm.io/gorm"
)

type HRWorkShiftsRepository interface {
	CheckOverlapShift(ctx context.Context, tx *gorm.DB, userID, date, startTime, endTime string) (bool, error)
	CreateShift(ctx context.Context, tx *gorm.DB, shift *domain.HRWorkShift) error
}

type hrWorkShiftsRepository struct{}

func NewHRWorkShiftsRepository() HRWorkShiftsRepository {
	return &hrWorkShiftsRepository{}
}

func (r *hrWorkShiftsRepository) CheckOverlapShift(ctx context.Context, tx *gorm.DB, userID, date, startTime, endTime string) (bool, error) {
	var count int64
	err := tx.Model(&domain.HRWorkShift{}).
		Where("user_id = ? AND date = ?", userID, date).
		Where("((start_time <= ? AND end_time > ?) OR (start_time < ? AND end_time >= ?))", startTime, startTime, endTime, endTime).
		Count(&count).Error
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

func (r *hrWorkShiftsRepository) CreateShift(ctx context.Context, tx *gorm.DB, shift *domain.HRWorkShift) error {
	return tx.Create(shift).Error
}
