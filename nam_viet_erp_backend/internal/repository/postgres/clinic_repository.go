package postgres

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/namvieterp/backend/internal/core/domain"
	"gorm.io/gorm"
)

type ClinicRepository interface {
	CheckDoctorAvailability(ctx context.Context, tx *gorm.DB, doctorID int64, appointmentTime time.Time) (bool, error)
	CreateAppointment(ctx context.Context, tx *gorm.DB, apt *domain.Appointment) error
	GetAppointmentByID(ctx context.Context, tx *gorm.DB, aptID string) (*domain.Appointment, error)
	UpdateAppointmentStatus(ctx context.Context, tx *gorm.DB, aptID string, status string, checkInTime *time.Time) error
	NotifyQueueUpdate(ctx context.Context, tx *gorm.DB, doctorID int64, action string, appointmentID string) error
}

type clinicRepository struct{}

func NewClinicRepository() ClinicRepository {
	return &clinicRepository{}
}

func (r *clinicRepository) CheckDoctorAvailability(ctx context.Context, tx *gorm.DB, doctorID int64, appointmentTime time.Time) (bool, error) {
	var count int64
	// Define "unavailable" as an overlapping appointment within a 30-minute window
	// For simplicity, we just check exact time or overlapping based on business rules.
	// Here we check if there's any pending/waiting appointment for the same doctor at the exact same minute.
	// In reality, this should be a range check.
	timeStart := appointmentTime.Add(-15 * time.Minute)
	timeEnd := appointmentTime.Add(15 * time.Minute)

	err := tx.WithContext(ctx).Model(&domain.Appointment{}).
		Where("doctor_id = ? AND status IN ('pending', 'waiting') AND appointment_time BETWEEN ? AND ?", doctorID, timeStart, timeEnd).
		Count(&count).Error
	
	if err != nil {
		return false, err
	}
	return count == 0, nil
}

func (r *clinicRepository) CreateAppointment(ctx context.Context, tx *gorm.DB, apt *domain.Appointment) error {
	return tx.WithContext(ctx).Create(apt).Error
}

func (r *clinicRepository) GetAppointmentByID(ctx context.Context, tx *gorm.DB, aptID string) (*domain.Appointment, error) {
	var apt domain.Appointment
	err := tx.WithContext(ctx).Where("id = ?", aptID).First(&apt).Error
	return &apt, err
}

func (r *clinicRepository) UpdateAppointmentStatus(ctx context.Context, tx *gorm.DB, aptID string, status string, checkInTime *time.Time) error {
	updates := map[string]interface{}{
		"status": status,
	}
	if checkInTime != nil {
		updates["check_in_time"] = checkInTime
	}
	return tx.WithContext(ctx).Model(&domain.Appointment{}).Where("id = ?", aptID).Updates(updates).Error
}

func (r *clinicRepository) NotifyQueueUpdate(ctx context.Context, tx *gorm.DB, doctorID int64, action string, appointmentID string) error {
	payload := map[string]interface{}{
		"doctor_id":      doctorID,
		"action":         action,
		"appointment_id": appointmentID,
	}
	payloadBytes, _ := json.Marshal(payload)
	// Execute PostgreSQL NOTIFY
	return tx.WithContext(ctx).Exec(fmt.Sprintf("NOTIFY clinic_queue_updates, '%s'", string(payloadBytes))).Error
}
