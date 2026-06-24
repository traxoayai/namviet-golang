package services

import (
	"context"
	"errors"
	"time"

	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/repository/postgres"
	"gorm.io/gorm"
)

type MedicalDictService interface {
	GetDiseases(ctx context.Context, tx *gorm.DB) ([]domain.MedicalDisease, error)
	GetPrescriptionTemplate(ctx context.Context, tx *gorm.DB, diseaseID int64, ageMonths int) (*domain.MedicalPrescriptionTemplate, error)
	GetVaccineProtocols(ctx context.Context, tx *gorm.DB) ([]domain.MedicalVaccineProtocol, error)
	CalculateNextDoseDate(ctx context.Context, tx *gorm.DB, req domain.VaccineNextDoseRequest) (*domain.VaccineNextDoseResponse, error)
}

type medicalDictService struct {
	repo postgres.MedicalDictRepository
}

func NewMedicalDictService(repo postgres.MedicalDictRepository) MedicalDictService {
	return &medicalDictService{repo: repo}
}

func (s *medicalDictService) GetDiseases(ctx context.Context, tx *gorm.DB) ([]domain.MedicalDisease, error) {
	return s.repo.GetDiseases(ctx, tx)
}

func (s *medicalDictService) GetPrescriptionTemplate(ctx context.Context, tx *gorm.DB, diseaseID int64, ageMonths int) (*domain.MedicalPrescriptionTemplate, error) {
	return s.repo.GetPrescriptionTemplate(ctx, tx, diseaseID, ageMonths)
}

func (s *medicalDictService) GetVaccineProtocols(ctx context.Context, tx *gorm.DB) ([]domain.MedicalVaccineProtocol, error) {
	return s.repo.GetVaccineProtocols(ctx, tx)
}

func (s *medicalDictService) CalculateNextDoseDate(ctx context.Context, tx *gorm.DB, req domain.VaccineNextDoseRequest) (*domain.VaccineNextDoseResponse, error) {
	protocol, err := s.repo.GetVaccineProtocol(ctx, tx, req.ProtocolID)
	if err != nil {
		return nil, err
	}

	var targetDose *domain.MedicalVaccineDose
	for _, d := range protocol.Doses {
		if d.DoseNumber == req.DoseNumber {
			targetDose = &d
			break
		}
	}

	if targetDose == nil {
		return nil, errors.New("dose_number not found in protocol")
	}

	lastDate, err := time.Parse("2006-01-02", req.LastInjectionDate)
	if err != nil {
		return nil, errors.New("invalid date format for last_injection_date, expected YYYY-MM-DD")
	}

	minDate := lastDate.AddDate(0, 0, targetDose.MinDaysFromPrevious)
	res := &domain.VaccineNextDoseResponse{
		NextDoseMinDate: minDate.Format("2006-01-02"),
	}

	if targetDose.MaxDaysFromPrevious != nil {
		maxDate := lastDate.AddDate(0, 0, *targetDose.MaxDaysFromPrevious)
		res.NextDoseMaxDate = maxDate.Format("2006-01-02")
	}

	return res, nil
}
