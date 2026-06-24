package main

import (
	"encoding/json"
	"io/ioutil"
	"log"
	"os"

	"github.com/joho/godotenv"
	"github.com/namvieterp/backend/internal/repository/postgres"
)

type DiseaseSeed struct {
	Dic10Code string   `json:"dic10_code"`
	Name      string   `json:"name"`
	Symptoms  []string `json:"symptoms"`
}

type MedicalDisease struct {
	ID        int64  `gorm:"primaryKey"`
	Dic10Code string `gorm:"uniqueIndex"`
	Name      string
	Symptoms  string `gorm:"type:jsonb"`
}

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, relying on OS env vars")
	}

	db, err := postgres.InitDB()
	if err != nil {
		log.Fatalf("Could not connect to database: %v", err)
	}

	jsonFile, err := os.Open("data/medical/dic10_diseases.json")
	if err != nil {
		log.Fatalf("Error opening JSON file: %v", err)
	}
	defer jsonFile.Close()

	byteValue, _ := ioutil.ReadAll(jsonFile)
	var diseases []DiseaseSeed
	if err := json.Unmarshal(byteValue, &diseases); err != nil {
		log.Fatalf("Error parsing JSON file: %v", err)
	}

	for _, d := range diseases {
		symptomsJSON, _ := json.Marshal(d.Symptoms)
		model := MedicalDisease{
			Dic10Code: d.Dic10Code,
			Name:      d.Name,
			Symptoms:  string(symptomsJSON),
		}

		// Insert or Ignore
		err := db.Table("medical_diseases").Where("dic10_code = ?", d.Dic10Code).FirstOrCreate(&model).Error
		if err != nil {
			log.Printf("Error inserting %s: %v\n", d.Dic10Code, err)
		} else {
			log.Printf("Successfully processed %s - %s\n", d.Dic10Code, d.Name)
		}
	}

	log.Println("Seed Data completed successfully.")
}
