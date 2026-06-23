package services

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"math"
	"net/http"
	"os"
	"time"

	"github.com/namvieterp/backend/internal/core/domain"
)

type SepayService struct {
	BaseURL      string
	ClientID     string
	ClientSecret string
}

func NewSepayService() *SepayService {
	// Fallback to sandbox credentials if env vars are not set
	clientID := os.Getenv("SEPAY_CLIENT_ID")
	if clientID == "" {
		clientID = "sandbox_client_id"
	}
	clientSecret := os.Getenv("SEPAY_CLIENT_SECRET")
	if clientSecret == "" {
		clientSecret = "sandbox_client_secret"
	}

	return &SepayService{
		BaseURL:      "https://einvoice-api.sepay.vn",
		ClientID:     clientID,
		ClientSecret: clientSecret,
	}
}

type TokenResponse struct {
	Success bool `json:"success"`
	Data    struct {
		AccessToken string `json:"access_token"`
	} `json:"data"`
}

func (s *SepayService) GetToken() (string, error) {
	// Bổ sung luồng bypass cho môi trường Test (dùng token hardcode do user cung cấp)
	testToken := os.Getenv("SEPAY_TEST_ACCESS_TOKEN")
	if testToken != "" {
		return testToken, nil
	}

	url := fmt.Sprintf("%s/v1/token", s.BaseURL)
	req, err := http.NewRequest("POST", url, nil)
	if err != nil {
		return "", err
	}

	authStr := fmt.Sprintf("%s:%s", s.ClientID, s.ClientSecret)
	encodedAuth := base64.StdEncoding.EncodeToString([]byte(authStr))
	req.Header.Set("Authorization", fmt.Sprintf("Basic %s", encodedAuth))
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("failed to get sepay token, status: %d", resp.StatusCode)
	}

	body, _ := ioutil.ReadAll(resp.Body)
	var tokenRes TokenResponse
	if err := json.Unmarshal(body, &tokenRes); err != nil {
		return "", err
	}

	if !tokenRes.Success {
		return "", fmt.Errorf("failed to get sepay token: response not success")
	}

	return tokenRes.Data.AccessToken, nil
}

type SepayBuyer struct {
	Type      string `json:"type"`
	Name      string `json:"name"`
	LegalName string `json:"legal_name"`
	TaxCode   string `json:"tax_code"`
	Address   string `json:"address"`
	Email     string `json:"email"`
}

type SepayItem struct {
	Name            string  `json:"name"`
	Unit            string  `json:"unit"`
	Quantity        float64 `json:"quantity"`
	UnitPrice       float64 `json:"unit_price"`
	TotalAmount     float64 `json:"total_amount"`
	DiscountAmount  float64 `json:"discount_amount"`
	TotalAmountPost float64 `json:"total_amount_post"`
	TaxRate         float64 `json:"tax_rate"`
	TaxAmount       float64 `json:"tax_amount"`
}

type SepayCreatePayload struct {
	InvoiceNumber string      `json:"invoice_number,omitempty"`
	InvoiceSymbol string      `json:"invoice_symbol,omitempty"`
	Currency      string      `json:"currency"`
	Buyer         SepayBuyer  `json:"buyer"`
	Items         []SepayItem `json:"items"`
	TotalAmount   float64     `json:"total_amount"`
	PaymentMethod string      `json:"payment_method"`
	IsDraft       bool        `json:"is_draft"`
}

func (s *SepayService) CreateInvoice(payload *domain.InvoicePayload, token string) (string, string, error) {
	buyerType := "personal"
	if len(payload.BuyerTaxCode) >= 10 {
		buyerType = "company"
	}

	buyerName := payload.BuyerName
	if buyerName == "" {
		buyerName = "Khách hàng"
	}

	sepayPayload := SepayCreatePayload{
		Currency: "VND",
		Buyer: SepayBuyer{
			Type:      buyerType,
			Name:      buyerName,
			LegalName: buyerName,
			TaxCode:   payload.BuyerTaxCode,
			Address:   payload.BuyerAddress,
			Email:     payload.BuyerEmail,
		},
		Items:         []SepayItem{},
		TotalAmount:   math.Round(payload.TotalAmountPostTax),
		PaymentMethod: "TM/CK",
		IsDraft:       payload.IsDraft,
	}

	for _, item := range payload.ItemsData {
		sepayPayload.Items = append(sepayPayload.Items, SepayItem{
			Name:            item.ProductNameRaw,
			Unit:            item.VendorUnit,
			Quantity:        item.Quantity,
			UnitPrice:       item.UnitPrice,
			TotalAmount:     item.TotalAmountPreVat,
			DiscountAmount:  item.DiscountAmount,
			TotalAmountPost: item.TotalAmountPreVat - item.DiscountAmount,
			TaxRate:         item.VatRate,
			TaxAmount:       math.Round((item.TotalAmountPreVat - item.DiscountAmount) * item.VatRate / 100),
		})
	}

	reqBody, _ := json.Marshal(sepayPayload)
	url := fmt.Sprintf("%s/v1/invoices/create", s.BaseURL)

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(reqBody))
	if err != nil {
		return "", "", err
	}

	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", token))
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return "", "", err
	}
	defer resp.Body.Close()

	body, _ := ioutil.ReadAll(resp.Body)
	if resp.StatusCode != 200 && resp.StatusCode != 201 {
		return "", "", fmt.Errorf("sepay create failed: %s", string(body))
	}

	var res struct {
		Success bool `json:"success"`
		Data    struct {
			ReferenceCode string `json:"reference_code"`
			TrackingCode  string `json:"tracking_code"`
		} `json:"data"`
	}

	if err := json.Unmarshal(body, &res); err != nil {
		return "", "", err
	}

	if !res.Success {
		return "", "", fmt.Errorf("sepay create response not success: %s", string(body))
	}

	return res.Data.ReferenceCode, res.Data.TrackingCode, nil
}

func (s *SepayService) IssueInvoice(referenceCode string, token string) (string, error) {
	payload := map[string]string{"reference_code": referenceCode}
	reqBody, _ := json.Marshal(payload)
	url := fmt.Sprintf("%s/v1/invoices/issue", s.BaseURL)

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(reqBody))
	if err != nil {
		return "", err
	}

	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", token))
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, _ := ioutil.ReadAll(resp.Body)
	if resp.StatusCode != 200 && resp.StatusCode != 201 {
		return "", fmt.Errorf("sepay issue failed: %s", string(body))
	}

	var res struct {
		Success bool `json:"success"`
		Data    struct {
			TrackingCode string `json:"tracking_code"`
		} `json:"data"`
	}

	if err := json.Unmarshal(body, &res); err != nil {
		return "", err
	}

	if !res.Success {
		return "", fmt.Errorf("sepay issue response not success: %s", string(body))
	}

	return res.Data.TrackingCode, nil
}

func (s *SepayService) CheckStatus(trackingCode string, token string) (string, string, string, error) {
	url := fmt.Sprintf("%s/v1/invoices/issue/check/%s", s.BaseURL, trackingCode)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return "", "", "", err
	}

	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", token))
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 30 * time.Second}
	
	// Polling logic
	maxAttempts := 5
	for attempt := 0; attempt < maxAttempts; attempt++ {
		resp, err := client.Do(req)
		if err != nil {
			return "", "", "", err
		}

		body, _ := ioutil.ReadAll(resp.Body)
		resp.Body.Close()

		if resp.StatusCode != 200 {
			return "", "", "", fmt.Errorf("sepay check status failed: %s", string(body))
		}

		var res struct {
			Success bool `json:"success"`
			Data    struct {
				Status        string `json:"status"`
				PdfUrl        string `json:"pdf_url"`
				ReferenceCode string `json:"reference_code"`
				InvoiceNumber string `json:"invoice_number"`
			} `json:"data"`
		}

		if err := json.Unmarshal(body, &res); err != nil {
			return "", "", "", err
		}

		if res.Success {
			if res.Data.Status == "issued" || res.Data.Status == "success" || res.Data.Status == "draft" {
				return res.Data.Status, res.Data.PdfUrl, res.Data.InvoiceNumber, nil
			}
		}

		// Wait before next attempt
		time.Sleep(1500 * time.Millisecond)
	}

	return "", "", "", fmt.Errorf("sepay check status timeout after %d attempts", maxAttempts)
}
