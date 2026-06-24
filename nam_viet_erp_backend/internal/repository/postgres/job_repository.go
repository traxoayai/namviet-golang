package postgres

import (
	"context"
	"time"

	"github.com/namvieterp/backend/internal/core/domain"
	"gorm.io/gorm"
)

type JobRepository interface {
	Enqueue(ctx context.Context, tx *gorm.DB, job *domain.Job) error
	FetchPendingJobs(ctx context.Context, tx *gorm.DB, limit int) ([]domain.Job, error)
	UpdateJobStatus(ctx context.Context, tx *gorm.DB, jobID int64, status string) error
}

type jobRepository struct{}

func NewJobRepository() JobRepository {
	return &jobRepository{}
}

func (r *jobRepository) Enqueue(ctx context.Context, tx *gorm.DB, job *domain.Job) error {
	job.Status = "pending"
	if job.RunAt.IsZero() {
		job.RunAt = time.Now()
	}
	return tx.Create(job).Error
}

func (r *jobRepository) FetchPendingJobs(ctx context.Context, tx *gorm.DB, limit int) ([]domain.Job, error) {
	var jobs []domain.Job
	// PostgreSQL SKIP LOCKED is essential for concurrent workers
	err := tx.Raw(`
		UPDATE jobs
		SET status = 'processing', updated_at = NOW()
		WHERE id IN (
			SELECT id FROM jobs
			WHERE status = 'pending' AND run_at <= NOW()
			ORDER BY run_at ASC
			FOR UPDATE SKIP LOCKED
			LIMIT ?
		)
		RETURNING *
	`, limit).Scan(&jobs).Error
	return jobs, err
}

func (r *jobRepository) UpdateJobStatus(ctx context.Context, tx *gorm.DB, jobID int64, status string) error {
	return tx.Model(&domain.Job{}).Where("id = ?", jobID).Updates(map[string]interface{}{
		"status":     status,
		"updated_at": time.Now(),
	}).Error
}
