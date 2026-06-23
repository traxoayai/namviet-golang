package domain

import "time"

// Appointment represents a clinic appointment booking
type Appointment struct {
	ID              string    `json:"id" gorm:"primaryKey;type:uuid;default:gen_random_uuid()"`
	DoctorID        int64     `json:"doctor_id"`
	PatientID       int64     `json:"patient_id"`
	ServiceType     string    `json:"service_type"` // e.g., 'examination'
	AppointmentTime time.Time `json:"appointment_time"`
	Status          string    `json:"status"` // 'pending', 'waiting', 'completed', 'cancelled'
	CheckInTime     *time.Time `json:"check_in_time"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

func (Appointment) TableName() string {
	return "appointments"
}

// BookAppointmentRequest payload
type BookAppointmentRequest struct {
	DoctorID        int64     `json:"doctor_id" binding:"required"`
	PatientID       int64     `json:"patient_id" binding:"required"`
	ServiceType     string    `json:"service_type" binding:"required"`
	AppointmentTime time.Time `json:"appointment_time" binding:"required"`
}

// CheckInRequest payload (can be empty or have extra notes)
type CheckInRequest struct {
	Notes string `json:"notes"`
}
