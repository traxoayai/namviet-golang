package domain

import (
	"time"
)

type MedicalDisease struct {
	ID        int64     `json:"id" gorm:"column:id;primaryKey"`
	Dic10Code string    `json:"dic10_code" gorm:"column:dic10_code"`
	Name      string    `json:"name" gorm:"column:name"`
	Symptoms  string    `json:"symptoms" gorm:"column:symptoms;type:jsonb"`
	CreatedAt time.Time `json:"created_at" gorm:"column:created_at"`
	UpdatedAt time.Time `json:"updated_at" gorm:"column:updated_at"`
}

func (MedicalDisease) TableName() string {
	return "medical_diseases"
}

type MedicalPrescriptionTemplate struct {
	ID           int64                            `json:"id" gorm:"column:id;primaryKey"`
	DiseaseID    int64                            `json:"disease_id" gorm:"column:disease_id"`
	MinAgeMonths int                              `json:"min_age_months" gorm:"column:min_age_months"`
	MaxAgeMonths int                              `json:"max_age_months" gorm:"column:max_age_months"`
	Items        []MedicalPrescriptionTemplateItem `json:"items" gorm:"foreignKey:TemplateID"`
	CreatedAt    time.Time                        `json:"created_at" gorm:"column:created_at"`
	UpdatedAt    time.Time                        `json:"updated_at" gorm:"column:updated_at"`
}

func (MedicalPrescriptionTemplate) TableName() string {
	return "medical_prescription_templates"
}

type MedicalPrescriptionTemplateItem struct {
	ID           int64     `json:"id" gorm:"column:id;primaryKey"`
	TemplateID   int64     `json:"template_id" gorm:"column:template_id"`
	ProductID    int64     `json:"product_id" gorm:"column:product_id"`
	Quantity     int       `json:"quantity" gorm:"column:quantity"`
	Dosage       string    `json:"dosage" gorm:"column:dosage"`
	Instructions string    `json:"instructions" gorm:"column:instructions"`
	CreatedAt    time.Time `json:"created_at" gorm:"column:created_at"`
	UpdatedAt    time.Time `json:"updated_at" gorm:"column:updated_at"`
}

func (MedicalPrescriptionTemplateItem) TableName() string {
	return "medical_prescription_template_items"
}

type MedicalVaccineProtocol struct {
	ID           int64                `json:"id" gorm:"column:id;primaryKey"`
	ProtocolName string               `json:"protocol_name" gorm:"column:protocol_name"`
	Doses        []MedicalVaccineDose `json:"doses" gorm:"foreignKey:ProtocolID"`
	CreatedAt    time.Time            `json:"created_at" gorm:"column:created_at"`
	UpdatedAt    time.Time            `json:"updated_at" gorm:"column:updated_at"`
}

func (MedicalVaccineProtocol) TableName() string {
	return "medical_vaccine_protocols"
}

type MedicalVaccineDose struct {
	ID                  int64     `json:"id" gorm:"column:id;primaryKey"`
	ProtocolID          int64     `json:"protocol_id" gorm:"column:protocol_id"`
	DoseNumber          int       `json:"dose_number" gorm:"column:dose_number"`
	MinDaysFromPrevious int       `json:"min_days_from_previous" gorm:"column:min_days_from_previous"`
	MaxDaysFromPrevious *int      `json:"max_days_from_previous" gorm:"column:max_days_from_previous"`
	CreatedAt           time.Time `json:"created_at" gorm:"column:created_at"`
	UpdatedAt           time.Time `json:"updated_at" gorm:"column:updated_at"`
}

func (MedicalVaccineDose) TableName() string {
	return "medical_vaccine_doses"
}

// Request / Response structures
type VaccineNextDoseRequest struct {
	ProtocolID         int64  `json:"protocol_id" binding:"required"`
	DoseNumber         int    `json:"dose_number" binding:"required"`
	LastInjectionDate  string `json:"last_injection_date" binding:"required"` // Format YYYY-MM-DD
}

type VaccineNextDoseResponse struct {
	NextDoseMinDate string `json:"next_dose_min_date"`
	NextDoseMaxDate string `json:"next_dose_max_date,omitempty"`
}
