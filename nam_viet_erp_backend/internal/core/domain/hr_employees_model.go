package domain

import (
	"time"
)

type Employee struct {
	ID              string    `json:"id" gorm:"column:id;primaryKey"`
	Email           string    `json:"email"`
	FullName        string    `json:"full_name"`
	AvatarUrl       string    `json:"avatar_url"`
	EmployeeCode    string    `json:"employee_code"`
	Position        string    `json:"position"`
	Status          string    `json:"status"`
	Dob             string    `json:"dob"`
	Phone           string    `json:"phone"`
	Gender          string    `json:"gender"`
	Cccd            string    `json:"cccd"`
	CccdIssueDate   string    `json:"cccd_issue_date"`
	Address         string                 `json:"address"`
	EducationLevel  string                 `json:"education_level"`
	Specialization  string                 `json:"specialization"`
	BankName        string                 `json:"bank_name"`
	BankAccount     string                 `json:"bank_account_number" gorm:"column:bank_account_number"`
	DepartmentID    *string                `json:"department_id" gorm:"column:department_id"` // Thêm theo yêu cầu KPI
	Permissions     map[string]interface{} `json:"permissions" gorm:"type:jsonb"`             // Thêm theo yêu cầu KPI
	CreatedAt       time.Time              `json:"created_at"`
	UpdatedAt       time.Time              `json:"updated_at"`
}

func (Employee) TableName() string {
	return "users"
}

// HR Employee Profile DTO that joins contracts, etc.
type EmployeeProfileDTO struct {
	Employee
	Contracts []HRContract `json:"contracts"`
	Payrolls  []HRPayroll  `json:"payrolls"`
}
