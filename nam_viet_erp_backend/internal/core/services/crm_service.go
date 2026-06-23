package services

import (
	"context"

	"github.com/namvieterp/backend/internal/core/domain"
	"github.com/namvieterp/backend/internal/repository/postgres"
	"gorm.io/gorm"
)

type CRMService interface {
	EarnLoyaltyPoints(ctx context.Context, tx *gorm.DB, req domain.EarnLoyaltyRequest) error
}

type crmService struct {
	repo postgres.CRMRepository
}

func NewCRMService(repo postgres.CRMRepository) CRMService {
	return &crmService{repo: repo}
}

func (s *crmService) EarnLoyaltyPoints(ctx context.Context, tx *gorm.DB, req domain.EarnLoyaltyRequest) error {
	// Rule: 100.000 VNĐ = 1 điểm
	pointsToEarn := int(req.Amount / 100000)

	if pointsToEarn > 0 {
		customer, err := s.repo.GetCustomerByID(ctx, tx, req.CustomerID)
		if err != nil {
			return err
		}

		newPoints := customer.LoyaltyPoints + pointsToEarn
		return s.repo.UpdateCustomerLoyaltyPoints(ctx, tx, req.CustomerID, newPoints)
	}

	return nil
}
