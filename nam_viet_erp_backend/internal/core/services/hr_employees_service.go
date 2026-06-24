package services

import (
	"context"
	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/repository/postgres"
	"gorm.io/gorm"
)

type HREmployeesService interface {
	GetEmployees(ctx context.Context, tx *gorm.DB, page, pageSize int) ([]domain.Employee, int64, error)
	GetEmployeeProfile(ctx context.Context, tx *gorm.DB, userID string) (*domain.EmployeeProfileDTO, error)
}

type hrEmployeesService struct {
	repo postgres.HREmployeesRepository
}

func NewHREmployeesService(repo postgres.HREmployeesRepository) HREmployeesService {
	return &hrEmployeesService{repo: repo}
}

func (s *hrEmployeesService) GetEmployees(ctx context.Context, tx *gorm.DB, page, pageSize int) ([]domain.Employee, int64, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 10
	}
	offset := (page - 1) * pageSize
	return s.repo.GetEmployees(ctx, tx, pageSize, offset)
}

func (s *hrEmployeesService) GetEmployeeProfile(ctx context.Context, tx *gorm.DB, userID string) (*domain.EmployeeProfileDTO, error) {
	return s.repo.GetEmployeeProfile(ctx, tx, userID)
}
