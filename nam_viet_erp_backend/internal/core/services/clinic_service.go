package services

import (
	"context"
	"errors"
	"time"

	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/repository/postgres"
	"gorm.io/gorm"
)

type ClinicService interface {
	BookAppointment(ctx context.Context, tx *gorm.DB, req domain.BookAppointmentRequest) (*domain.Appointment, error)
	CheckInPatient(ctx context.Context, tx *gorm.DB, appointmentID string) error
}

type clinicService struct {
	repo postgres.ClinicRepository
}

func NewClinicService(repo postgres.ClinicRepository) ClinicService {
	return &clinicService{repo: repo}
}

func (s *clinicService) BookAppointment(ctx context.Context, tx *gorm.DB, req domain.BookAppointmentRequest) (*domain.Appointment, error) {
	available, err := s.repo.CheckDoctorAvailability(ctx, tx, req.DoctorID, req.AppointmentTime)
	if err != nil {
		return nil, err
	}
	if !available {
		return nil, errors.New("bác sĩ đã kín lịch vào khoảng thời gian này")
	}

	apt := &domain.Appointment{
		DoctorID:        req.DoctorID,
		PatientID:       req.PatientID,
		ServiceType:     req.ServiceType,
		AppointmentTime: req.AppointmentTime,
		Status:          "pending",
	}

	if err := s.repo.CreateAppointment(ctx, tx, apt); err != nil {
		return nil, err
	}
	return apt, nil
}

func (s *clinicService) CheckInPatient(ctx context.Context, tx *gorm.DB, appointmentID string) error {
	apt, err := s.repo.GetAppointmentByID(ctx, tx, appointmentID)
	if err != nil {
		return errors.New("không tìm thấy lịch hẹn")
	}

	if apt.Status != "pending" {
		return errors.New("chỉ có thể check-in lịch hẹn ở trạng thái pending")
	}

	now := time.Now()
	if err := s.repo.UpdateAppointmentStatus(ctx, tx, appointmentID, "waiting", &now); err != nil {
		return err
	}

	// Trigger Notify for Websocket Queue
	if err := s.repo.NotifyQueueUpdate(ctx, tx, apt.DoctorID, "new_patient", appointmentID); err != nil {
		return err
	}

	return nil
}
