package postgres

import (
	"context"

	"github.com/namvieterp/backend/internal/core/domain"
	"gorm.io/gorm"
)

type MedicalDictRepository interface {
	GetDiseases(ctx context.Context, tx *gorm.DB) ([]domain.MedicalDisease, error)
	GetPrescriptionTemplate(ctx context.Context, tx *gorm.DB, diseaseID int64, ageMonths int) (*domain.MedicalPrescriptionTemplate, error)
	GetVaccineProtocols(ctx context.Context, tx *gorm.DB) ([]domain.MedicalVaccineProtocol, error)
	GetVaccineProtocol(ctx context.Context, tx *gorm.DB, protocolID int64) (*domain.MedicalVaccineProtocol, error)
}

type medicalDictRepository struct{}

func NewMedicalDictRepository() MedicalDictRepository {
	return &medicalDictRepository{}
}

func (r *medicalDictRepository) GetDiseases(ctx context.Context, tx *gorm.DB) ([]domain.MedicalDisease, error) {
	var diseases []domain.MedicalDisease
	err := tx.Order("dic10_code asc").Find(&diseases).Error
	return diseases, err
}

func (r *medicalDictRepository) GetPrescriptionTemplate(ctx context.Context, tx *gorm.DB, diseaseID int64, ageMonths int) (*domain.MedicalPrescriptionTemplate, error) {
	var template domain.MedicalPrescriptionTemplate
	err := tx.Preload("Items").
		Where("disease_id = ?", diseaseID).
		Where("min_age_months <= ? AND max_age_months >= ?", ageMonths, ageMonths).
		First(&template).Error
	if err != nil {
		return nil, err
	}
	return &template, nil
}

func (r *medicalDictRepository) GetVaccineProtocols(ctx context.Context, tx *gorm.DB) ([]domain.MedicalVaccineProtocol, error) {
	var protocols []domain.MedicalVaccineProtocol
	err := tx.Find(&protocols).Error
	return protocols, err
}

func (r *medicalDictRepository) GetVaccineProtocol(ctx context.Context, tx *gorm.DB, protocolID int64) (*domain.MedicalVaccineProtocol, error) {
	var protocol domain.MedicalVaccineProtocol
	err := tx.Preload("Doses", func(db *gorm.DB) *gorm.DB {
		return db.Order("medical_vaccine_doses.dose_number ASC")
	}).First(&protocol, protocolID).Error
	if err != nil {
		return nil, err
	}
	return &protocol, nil
}
