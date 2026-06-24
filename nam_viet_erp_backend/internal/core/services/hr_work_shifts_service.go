package services

import (
	"context"
	"errors"
	"math"
	"time"

	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/repository/postgres"
	"gorm.io/gorm"
)

type HRWorkShiftsService interface {
	RegisterShift(ctx context.Context, tx *gorm.DB, userID string, req domain.ShiftRegisterRequest) (*domain.HRWorkShift, error)
	CheckIn(ctx context.Context, tx *gorm.DB, userID, ip string, req domain.HRCheckInRequest) (*domain.HRCheckInResponse, error)
}

type hrWorkShiftsService struct {
	shiftRepo      postgres.HRWorkShiftsRepository
	attendanceRepo postgres.HRAttendancesRepository
}

func NewHRWorkShiftsService(sRepo postgres.HRWorkShiftsRepository, aRepo postgres.HRAttendancesRepository) HRWorkShiftsService {
	return &hrWorkShiftsService{shiftRepo: sRepo, attendanceRepo: aRepo}
}

func (s *hrWorkShiftsService) RegisterShift(ctx context.Context, tx *gorm.DB, userID string, req domain.ShiftRegisterRequest) (*domain.HRWorkShift, error) {
	overlap, err := s.shiftRepo.CheckOverlapShift(ctx, tx, userID, req.Date, req.StartTime, req.EndTime)
	if err != nil {
		return nil, err
	}
	if overlap {
		return nil, errors.New("Khung giờ này đã bị trùng lặp với ca đã đăng ký!")
	}

	shift := &domain.HRWorkShift{
		UserID:    userID,
		ShiftName: req.ShiftName,
		Date:      req.Date,
		StartTime: req.StartTime,
		EndTime:   req.EndTime,
		Status:    "pending",
	}

	if err := s.shiftRepo.CreateShift(ctx, tx, shift); err != nil {
		return nil, err
	}

	return shift, nil
}

func (s *hrWorkShiftsService) CheckIn(ctx context.Context, tx *gorm.DB, userID, ip string, req domain.HRCheckInRequest) (*domain.HRCheckInResponse, error) {
	// Branch Coordinates (Mocked for NamViet ERP Main Branch)
	branchLat := 10.762622
	branchLng := 106.660172

	distance := haversine(req.Lat, req.Lng, branchLat, branchLng)
	isValid := distance <= 50.0

	now := time.Now()

	att := &domain.HRAttendance{
		ShiftID:            req.ShiftID,
		UserID:             userID,
		CheckInTime:        &now,
		CheckInIp:          ip,
		CheckInLat:         req.Lat,
		CheckInLng:         req.Lng,
		DistanceFromBranch: distance,
		IsValidLocation:    isValid,
	}

	if err := s.attendanceRepo.CreateAttendance(ctx, tx, att); err != nil {
		return nil, err
	}

	return &domain.HRCheckInResponse{
		Message:  "Check-in thành công!",
		Distance: distance,
		IsValid:  isValid,
	}, nil
}

// Haversine formula to calculate distance in meters
func haversine(lat1, lon1, lat2, lon2 float64) float64 {
	const R = 6371000 // Earth radius in meters
	dLat := (lat2 - lat1) * math.Pi / 180.0
	dLon := (lon2 - lon1) * math.Pi / 180.0
	lat1Rad := lat1 * math.Pi / 180.0
	lat2Rad := lat2 * math.Pi / 180.0

	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Sin(dLon/2)*math.Sin(dLon/2)*math.Cos(lat1Rad)*math.Cos(lat2Rad)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))

	return R * c
}
