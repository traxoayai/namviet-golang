package domain

// GHNCreateOrderRequest represents the payload sent to GHN
type GHNCreateOrderRequest struct {
	ToName    string `json:"to_name"`
	ToPhone   string `json:"to_phone"`
	ToAddress string `json:"to_address"`
	ToWardCode string `json:"to_ward_code"`
	ToDistrictID int `json:"to_district_id"`
	Weight    int    `json:"weight"`
	Length    int    `json:"length"`
	Width     int    `json:"width"`
	Height    int    `json:"height"`
	Items     []GHNItem `json:"items"`
}

type GHNItem struct {
	Name     string `json:"name"`
	Quantity int    `json:"quantity"`
}

// GHNWebhookPayload represents the webhook payload from GHN
type GHNWebhookPayload struct {
	OrderCode    string `json:"OrderCode"`
	Status       string `json:"Status"`
	Time         string `json:"Time"`
	TotalFee     int    `json:"TotalFee"`
	ClientOrderCode string `json:"ClientOrderCode"`
}
