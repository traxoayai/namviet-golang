package handlers

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/gin-gonic/gin"
	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/stretchr/testify/assert"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type MockClinicService struct {
	Available bool
}

func (m *MockClinicService) BookAppointment(ctx context.Context, tx *gorm.DB, req domain.BookAppointmentRequest) (*domain.Appointment, error) {
	if !m.Available {
		return nil, errors.New("bác sĩ đã kín lịch vào khoảng thời gian này")
	}
	return &domain.Appointment{
		ID:              "uuid-1234",
		DoctorID:        req.DoctorID,
		PatientID:       req.PatientID,
		ServiceType:     req.ServiceType,
		AppointmentTime: req.AppointmentTime,
		Status:          "pending",
	}, nil
}

func (m *MockClinicService) CheckInPatient(ctx context.Context, tx *gorm.DB, appointmentID string) error {
	return nil
}

func setupClinicTestDB() (*gorm.DB, sqlmock.Sqlmock) {
	db, mock, _ := sqlmock.New()
	gormDB, _ := gorm.Open(postgres.New(postgres.Config{
		Conn: db,
	}), &gorm.Config{})
	return gormDB, mock
}

func TestBookAppointment_Conflict(t *testing.T) {
	gin.SetMode(gin.TestMode)
	gormDB, mock := setupClinicTestDB()
	
	mock.ExpectBegin()
	mock.ExpectRollback()

	mockSvc := &MockClinicService{Available: false}
	handler := NewClinicHandler(gormDB, mockSvc)

	r := gin.Default()
	r.POST("/appointments", handler.BookAppointment)

	reqPayload := domain.BookAppointmentRequest{
		DoctorID:        1,
		PatientID:       2,
		ServiceType:     "examination",
		AppointmentTime: time.Now(),
	}
	jsonBody, _ := json.Marshal(reqPayload)

	req, _ := http.NewRequest(http.MethodPost, "/appointments", bytes.NewBuffer(jsonBody))
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
	assert.Contains(t, w.Body.String(), "bác sĩ đã kín lịch")
}

func TestBookAppointment_Success(t *testing.T) {
	gin.SetMode(gin.TestMode)
	gormDB, mock := setupClinicTestDB()
	
	mock.ExpectBegin()
	mock.ExpectCommit()

	mockSvc := &MockClinicService{Available: true}
	handler := NewClinicHandler(gormDB, mockSvc)

	r := gin.Default()
	r.POST("/appointments", handler.BookAppointment)

	reqPayload := domain.BookAppointmentRequest{
		DoctorID:        1,
		PatientID:       2,
		ServiceType:     "examination",
		AppointmentTime: time.Now(),
	}
	jsonBody, _ := json.Marshal(reqPayload)

	req, _ := http.NewRequest(http.MethodPost, "/appointments", bytes.NewBuffer(jsonBody))
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Body.String(), "uuid-1234")
}
