package services

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/namvieterp/backend/internal/core/domain"
	"gorm.io/gorm"
)

type GdtService struct {
	db *gorm.DB
}

func NewGdtService(db *gorm.DB) *GdtService {
	return &GdtService{db: db}
}

// UpdateToken updates the GDT JWT token in the database
func (s *GdtService) UpdateToken(token string) error {
	setting := domain.SystemSetting{
		Key: "gdt_token",
		Value: domain.JSONB{
			"token":      token,
			"status":     "active",
			"updated_at": time.Now().Format(time.RFC3339),
		},
	}
	return s.db.Save(&setting).Error
}

// GetTokenStatus returns the current connection status to GDT
func (s *GdtService) GetTokenStatus() (map[string]interface{}, error) {
	var setting domain.SystemSetting
	err := s.db.Where("key = ?", "gdt_token").First(&setting).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return map[string]interface{}{"status": "disconnected"}, nil
		}
		return nil, err
	}
	return setting.Value, nil
}

// SetTokenDisconnected marks the current token as disconnected/expired
func (s *GdtService) SetTokenDisconnected() error {
	var setting domain.SystemSetting
	if err := s.db.Where("key = ?", "gdt_token").First(&setting).Error; err != nil {
		return err
	}
	setting.Value["status"] = "disconnected"
	setting.Value["updated_at"] = time.Now().Format(time.RFC3339)
	return s.db.Save(&setting).Error
}

func (s *GdtService) GetActiveToken() (string, error) {
	var setting domain.SystemSetting
	err := s.db.Where("key = ?", "gdt_token").First(&setting).Error
	if err != nil {
		return "", err
	}
	if status, ok := setting.Value["status"].(string); !ok || status != "active" {
		return "", fmt.Errorf("token is disconnected")
	}
	token, ok := setting.Value["token"].(string)
	if !ok {
		return "", fmt.Errorf("token missing in config")
	}
	return token, nil
}

// FetchList calls the GDT API to get the list of invoices
func (s *GdtService) FetchList(token, startDate, endDate string, isOutbound bool) ([]interface{}, error) {
	state := "1" // Mua vao
	if isOutbound {
		state = "2" // Ban ra
	}

	url := fmt.Sprintf("https://hoadondientu.gdt.gov.vn/api/query/invoices/search?sort=tdlap:DESC,khmshdon:ASC,shdon:DESC&size=1000&search=tdlap=ge=%sT00:00:00;tdlap=le=%sT23:59:59;ttxly=eq=5&state=%s", startDate, endDate, state)
	
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+token)

	client := &http.Client{Timeout: 15 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode == 401 || resp.StatusCode == 403 {
		s.SetTokenDisconnected()
		return nil, fmt.Errorf("auth error: %d", resp.StatusCode)
	}

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("gdt list api error: %d", resp.StatusCode)
	}

	bodyBytes, _ := io.ReadAll(resp.Body)
	var data map[string]interface{}
	if err := json.Unmarshal(bodyBytes, &data); err != nil {
		return nil, err
	}

	datas, ok := data["datas"].([]interface{})
	if !ok {
		return []interface{}{}, nil
	}
	return datas, nil
}

// FetchDetail calls GDT API to get details of a specific invoice
func (s *GdtService) FetchDetail(token, nbmst, khhdon, shdon, khmshdon string) (map[string]interface{}, error) {
	url := fmt.Sprintf("https://hoadondientu.gdt.gov.vn/api/query/invoices/detail?nbmst=%s&khhdon=%s&shdon=%s&khmshdon=%s", nbmst, khhdon, shdon, khmshdon)

	for attempt := 1; attempt <= 3; attempt++ {
		req, err := http.NewRequest("GET", url, nil)
		if err != nil {
			return nil, err
		}
		req.Header.Set("Authorization", "Bearer "+token)

		client := &http.Client{Timeout: 10 * time.Second}
		resp, err := client.Do(req)

		if err == nil {
			defer resp.Body.Close()

			if resp.StatusCode == 200 {
				bodyBytes, _ := io.ReadAll(resp.Body)
				var data map[string]interface{}
				if err := json.Unmarshal(bodyBytes, &data); err == nil {
					return data, nil
				}
			} else if resp.StatusCode == 401 || resp.StatusCode == 403 {
				s.SetTokenDisconnected()
				return nil, fmt.Errorf("auth error")
			} else if resp.StatusCode == 429 {
				time.Sleep(30 * time.Second) // WAF rate limit, sleep heavily
				continue
			}
		}

		time.Sleep(5 * time.Second)
	}

	return nil, fmt.Errorf("failed to fetch detail after retries")
}
