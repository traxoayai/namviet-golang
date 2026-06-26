package postgres

import (
	"context"

	"github.com/namvieterp/backend/internal/core/domain"
	"gorm.io/gorm"
)

type HRKPIRepository interface {
	CreateTarget(ctx context.Context, tx *gorm.DB, target *domain.HRKPITarget) error
	GetTargetsByEmployee(ctx context.Context, tx *gorm.DB, employeeID string, month, year int) ([]domain.HRKPITarget, error)
	GetAllRewardRules(ctx context.Context, tx *gorm.DB) ([]domain.HRKPIRewardRule, error)
	GetAllMetrics(ctx context.Context, tx *gorm.DB) ([]domain.HRKPIMetric, error)
	GetEmployeeByID(ctx context.Context, tx *gorm.DB, employeeID string) (*domain.Employee, error)
}

type hrKpiRepository struct {
	db *gorm.DB
}

func NewHRKPIRepository(db *gorm.DB) HRKPIRepository {
	return &hrKpiRepository{db: db}
}

func (r *hrKpiRepository) CreateTarget(ctx context.Context, tx *gorm.DB, target *domain.HRKPITarget) error {
	db := r.db
	if tx != nil {
		db = tx
	}
	return db.WithContext(ctx).Create(target).Error
}

func (r *hrKpiRepository) GetTargetsByEmployee(ctx context.Context, tx *gorm.DB, employeeID string, month, year int) ([]domain.HRKPITarget, error) {
	db := r.db
	if tx != nil {
		db = tx
	}
	var targets []domain.HRKPITarget
	err := db.WithContext(ctx).Where("employee_id = ? AND month = ? AND year = ?", employeeID, month, year).Find(&targets).Error
	return targets, err
}

func (r *hrKpiRepository) GetAllRewardRules(ctx context.Context, tx *gorm.DB) ([]domain.HRKPIRewardRule, error) {
	db := r.db
	if tx != nil {
		db = tx
	}
	var rules []domain.HRKPIRewardRule
	err := db.WithContext(ctx).Find(&rules).Error
	return rules, err
}

func (r *hrKpiRepository) GetEmployeeByID(ctx context.Context, tx *gorm.DB, employeeID string) (*domain.Employee, error) {
	db := r.db
	if tx != nil {
		db = tx
	}
	var emp domain.Employee
	err := db.WithContext(ctx).Where("id = ?", employeeID).First(&emp).Error
	return &emp, err
}

func (r *hrKpiRepository) GetAllMetrics(ctx context.Context, tx *gorm.DB) ([]domain.HRKPIMetric, error) {
	db := r.db
	if tx != nil {
		db = tx
	}
	var metrics []domain.HRKPIMetric
	err := db.WithContext(ctx).Find(&metrics).Error
	return metrics, err
}
