package postgres

import (
	"context"
	"github.com/namvieterp/backend/internal/core/domain"
	"gorm.io/gorm"
)

type HRAttendancesRepository interface {
	CreateAttendance(ctx context.Context, tx *gorm.DB, attendance *domain.HRAttendance) error
	GetAttendanceByShift(ctx context.Context, tx *gorm.DB, shiftID int64) (*domain.HRAttendance, error)
}

type hrAttendancesRepository struct{}

func NewHRAttendancesRepository() HRAttendancesRepository {
	return &hrAttendancesRepository{}
}

func (r *hrAttendancesRepository) CreateAttendance(ctx context.Context, tx *gorm.DB, attendance *domain.HRAttendance) error {
	return tx.Create(attendance).Error
}

func (r *hrAttendancesRepository) GetAttendanceByShift(ctx context.Context, tx *gorm.DB, shiftID int64) (*domain.HRAttendance, error) {
	var att domain.HRAttendance
	err := tx.Where("shift_id = ?", shiftID).First(&att).Error
	if err != nil {
		return nil, err
	}
	return &att, nil
}
