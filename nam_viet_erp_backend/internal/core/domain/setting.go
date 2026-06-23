package domain

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
)

type JSONB map[string]interface{}

// Value Marshal
func (a JSONB) Value() (driver.Value, error) {
	return json.Marshal(a)
}

// Scan Unmarshal
func (a *JSONB) Scan(value interface{}) error {
	if value == nil {
		*a = nil
		return nil
	}
	b, ok := value.([]byte)
	if !ok {
		// sometimes it comes as string
		s, ok := value.(string)
		if !ok {
			return errors.New("type assertion to []byte or string failed")
		}
		b = []byte(s)
	}
	return json.Unmarshal(b, &a)
}

type SystemSetting struct {
	Key   string `gorm:"primaryKey;column:key"`
	Value JSONB  `gorm:"type:jsonb;column:value"`
}

func (SystemSetting) TableName() string {
	return "system_settings"
}
