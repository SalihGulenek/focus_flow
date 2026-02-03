# Phase 1: Database Setup & Models

## Amaç
Veritabanı bağlantısını kurmak ve tüm modelleri tanımlamak.

---

## 1.1 Proje Yapısını Oluştur

```bash
mkdir -p internal/{config,models,repository,services,handlers,middleware}
mkdir -p cmd/migrate
mkdir -p docs
```

## 1.2 Go Modülünü Başlat

```bash
go mod init github.com/ozlucodes/focusflow
```

## 1.3 Gerekli Kütüphaneleri Yükle

```bash
# Core Framework
go get github.com/gofiber/fiber/v2
go get github.com/gofiber/fiber/v2/middleware/logger
go get github.com/gofiber/fiber/v2/middleware/cors
go get github.com/gofiber/fiber/v2/middleware/limiter

# Database
go get gorm.io/gorm
go get gorm.io/driver/postgres

# Utils
go get github.com/google/uuid
go get github.com/joho/godotenv
go get golang.org/x/crypto/bcrypt
go get github.com/golang-jwt/jwt/v5

# Validation
go get github.com/go-playground/validator/v10

# Time handling
go get github.com/robfig/cron/v3
```

---

## 2.1 Supabase Bağlantı Config

**Dosya:** `internal/config/database.go`

```go
package config

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/joho/godotenv"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

type Config struct {
	DBHost     string
	DBPort     string
	DBUser     string
	DBPassword string
	DBName     string
	DBSSLMode  string
	JWTSecret  string
	Port       string
}

func LoadConfig() *Config {
	godotenv.Load()

	return &Config{
		DBHost:     getEnv("DB_HOST", ""),
		DBPort:     getEnv("DB_PORT", "5432"),
		DBUser:     getEnv("DB_USER", "postgres"),
		DBPassword: getEnv("DB_PASSWORD", ""),
		DBName:     getEnv("DB_NAME", "postgres"),
		DBSSLMode:  getEnv("DB_SSLMODE", "require"),
		JWTSecret:  getEnv("JWT_SECRET", ""),
		Port:       getEnv("PORT", "3000"),
	}
}

func InitDB(cfg *Config) *gorm.DB {
	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		cfg.DBHost, cfg.DBPort, cfg.DBUser, cfg.DBPassword, cfg.DBName, cfg.DBSSLMode,
	)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
		NowFunc: func() time.Time {
			return time.Now().UTC()
		},
	})

	if err != nil {
		log.Fatal("Failed to connect to Supabase:", err)
	}

	// Connection pool ayarları
	sqlDB, err := db.DB()
	if err != nil {
		log.Fatal("Failed to get database instance:", err)
	}

	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetMaxOpenConns(100)
	sqlDB.SetConnMaxLifetime(time.Hour)

	log.Println("Connected to Supabase PostgreSQL successfully!")
	return db
}

func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
```

---

## 2.2 User Model

**Dosya:** `internal/models/user.go`

```go
package models

import (
	"time"

	"github.com/google/uuid"
)

type User struct {
	ID           uuid.UUID `gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	Email        string    `gorm:"type:varchar(255);uniqueIndex;not null" validate:"required,email"`
	PasswordHash string    `gorm:"type:varchar(255);not null" validate:"required,min=8,max=72"`
	FullName     string    `gorm:"type:varchar(100)"`
	AvatarURL    string    `gorm:"type:varchar(500)"`
	Timezone     string    `gorm:"type:varchar(50);default:'Europe/Istanbul'"`
	CreatedAt    time.Time `gorm:"autoCreateTime"`
	UpdatedAt    time.Time `gorm:"autoUpdateTime"`
}

func (User) TableName() string {
	return "users"
}
```

---

## 2.3 Task Model

**Dosya:** `internal/models/task.go`

```go
package models

import (
	"time"

	"github.com/google/uuid"
)

type TaskStatus string
type TaskPriority int

const (
	TaskStatusPending   TaskStatus = "PENDING"
	TaskStatusActive    TaskStatus = "ACTIVE"
	TaskStatusBlocked   TaskStatus = "BLOCKED"
	TaskStatusCompleted TaskStatus = "COMPLETED"
	TaskStatusArchived  TaskStatus = "ARCHIVED"
)

const (
	PriorityCritical TaskPriority = 1
	PriorityHigh     TaskPriority = 2
	PriorityMedium   TaskPriority = 3
	PriorityLow      TaskPriority = 4
	PriorityMinimal  TaskPriority = 5
)

const (
	RecurrenceDaily    = "DAILY"
	RecurrenceWeekly   = "WEEKLY"
	RecurrenceWeekdays = "WEEKDAYS"
	RecurrenceMonthly  = "MONTHLY"
)

type Task struct {
	ID             uuid.UUID   `gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	UserID         uuid.UUID   `gorm:"type:uuid;not null;index" validate:"required"`
	User           User        `gorm:"foreignKey:UserID"`
	Title          string      `gorm:"type:varchar(255);not null" validate:"required,min=1,max=255"`
	Description    string      `gorm:"type:text"`
	Status         TaskStatus  `gorm:"type:varchar(20);not null;default:'PENDING';index"`
	Priority       int         `gorm:"type:int;not null;default:3;check:priority >= 1 AND priority <= 5" validate:"min=1,max=5"`
	DueDate        *time.Time  `gorm:"index"`
	IsRecurring    bool        `gorm:"type:boolean;not null;default:false;index"`
	RecurrenceRule *string     `gorm:"type:varchar(100)"`
	RecurrenceEnd  *time.Time  `gorm:"type:timestamp"`
	ParentID       *uuid.UUID  `gorm:"type:uuid;index"`
	CompletedAt    *time.Time
	CreatedAt      time.Time   `gorm:"autoCreateTime"`
	UpdatedAt      time.Time   `gorm:"autoUpdateTime"`

	// Relationships
	Parent         *Task            `gorm:"constraint:OnDelete:CASCADE;foreignKey:ParentID"`
	Subtasks       []Task           `gorm:"constraint:OnDelete:CASCADE;foreignKey:ParentID"`
	Dependencies   []TaskDependency `gorm:"foreignKey:BlockedTaskID;constraint:OnDelete:CASCADE"`
	BlockedBy      []TaskDependency `gorm:"foreignKey:BlockerTaskID;constraint:OnDelete:CASCADE"`
	Reminders      []Reminder       `gorm:"foreignKey:TaskID;constraint:OnDelete:CASCADE"`
	Tags           []Tag            `gorm:"many2many:task_tags;"`
	FocusSessions  []FocusSession   `gorm:"foreignKey:TaskID;constraint:OnDelete:SET NULL"`
}

func (Task) TableName() string {
	return "tasks"
}

// Helper methods
func (t *Task) IsCompleted() bool {
	return t.Status == TaskStatusCompleted
}

func (t *Task) IsBlocked() bool {
	return t.Status == TaskStatusBlocked
}

func (t *Task) IsActive() bool {
	return t.Status == TaskStatusActive
}

func (t *Task) CanBeStarted() bool {
	return t.Status == TaskStatusPending
}

func (t *Task) IsSubtask() bool {
	return t.ParentID != nil
}

func (t *Task) GetPriorityLabel() string {
	switch TaskPriority(t.Priority) {
	case PriorityCritical:
		return "Critical"
	case PriorityHigh:
		return "High"
	case PriorityMedium:
		return "Medium"
	case PriorityLow:
		return "Low"
	case PriorityMinimal:
		return "Minimal"
	default:
		return "Medium"
	}
}

func (t *Task) GetPriorityColor() string {
	switch TaskPriority(t.Priority) {
	case PriorityCritical:
		return "#FF5252"
	case PriorityHigh:
		return "#FF9800"
	case PriorityMedium:
		return "#2196F3"
	case PriorityLow:
		return "#4CAF50"
	case PriorityMinimal:
		return "#9E9E9E"
	default:
		return "#2196F3"
	}
}
```

---

## 2.4 TaskDependency Model

**Dosya:** `internal/models/task_dependency.go`

```go
package models

import (
	"time"

	"github.com/google/uuid"
)

type TaskDependency struct {
	BlockerTaskID uuid.UUID `gorm:"type:uuid;primaryKey;not null"`
	Blocker       Task      `gorm:"foreignKey:BlockerTaskID;constraint:OnDelete:CASCADE"`
	BlockedTaskID uuid.UUID `gorm:"type:uuid;primaryKey;not null"`
	Blocked       Task      `gorm:"foreignKey:BlockedTaskID;constraint:OnDelete:CASCADE"`
	CreatedAt     time.Time `gorm:"autoCreateTime"`
}

func (TaskDependency) TableName() string {
	return "task_dependencies"
}
```

---

## 2.5 Reminder Model

**Dosya:** `internal/models/reminder.go`

```go
package models

import (
	"time"

	"github.com/google/uuid"
)

type Reminder struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	TaskID    uuid.UUID `gorm:"type:uuid;not null;index" validate:"required"`
	Task      Task      `gorm:"foreignKey:TaskID;constraint:OnDelete:CASCADE"`
	RemindAt  time.Time `gorm:"type:timestamp;not null;index" validate:"required"`
	IsSent    bool      `gorm:"type:boolean;not null;default:false;index"`
	SentAt    *time.Time
	CreatedAt time.Time `gorm:"autoCreateTime"`
}

func (Reminder) TableName() string {
	return "reminders"
}
```

---

## 2.6 Tag Model

**Dosya:** `internal/models/tag.go`

```go
package models

import (
	"time"

	"github.com/google/uuid"
)

type Tag struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	UserID    uuid.UUID `gorm:"type:uuid;not null;index" validate:"required"`
	User      User      `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE"`
	Name      string    `gorm:"type:varchar(50);not null" validate:"required,min=1,max=50"`
	Color     string    `gorm:"type:varchar(7)" validate:"hexcolor,len=7"`
	CreatedAt time.Time `gorm:"autoCreateTime"`

	Tasks []Task `gorm:"many2many:task_tags;"`
}

func (Tag) TableName() string {
	return "tags"
}
```

---

## 2.7 FocusSession Model

**Dosya:** `internal/models/focus_session.go`

```go
package models

import (
	"time"

	"github.com/google/uuid"
)

type SessionStatus string

const (
	SessionStatusRunning   SessionStatus = "RUNNING"
	SessionStatusCompleted SessionStatus = "COMPLETED"
	SessionStatusCancelled SessionStatus = "CANCELLED"
	SessionStatusPaused    SessionStatus = "PAUSED"
)

type FocusSession struct {
	ID          uuid.UUID    `gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	TaskID      *uuid.UUID   `gorm:"type:uuid;index"`
	Task        *Task        `gorm:"foreignKey:TaskID"`
	UserID      uuid.UUID    `gorm:"type:uuid;not null;index" validate:"required"`
	User        User         `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE"`
	Duration    int          `gorm:"type:int;not null;default:25" validate:"min=1,max=120"`
	Status      SessionStatus `gorm:"type:varchar(20);not null;default:'RUNNING';index"`
	StartedAt   time.Time    `gorm:"type:timestamp;not null" validate:"required"`
	CompletedAt *time.Time
	PausedAt    *time.Time
	TotalPaused int          `gorm:"type:int;default:0"`
	CreatedAt   time.Time    `gorm:"autoCreateTime"`
}

func (FocusSession) TableName() string {
	return "focus_sessions"
}

func (f *FocusSession) IsRunning() bool {
	return f.Status == SessionStatusRunning
}

func (f *FocusSession) IsPaused() bool {
	return f.Status == SessionStatusPaused
}

func (f *FocusSession) IsCompleted() bool {
	return f.Status == SessionStatusCompleted
}

func (f *FocusSession) GetActualDuration() int {
	// Dakika cinsinden actual duration
	pausedMinutes := f.TotalPaused / 60
	actualDuration := f.Duration - pausedMinutes
	if actualDuration < 0 {
		return 0
	}
	return actualDuration
}
```

---

## 2.8 Error Response Models

**Dosya:** `internal/models/error.go`

```go
package models

type ErrorResponse struct {
	Error ErrorDetail `json:"error"`
}

type ErrorDetail struct {
	Code    string         `json:"code"`
	Message string         `json:"message"`
	Details map[string]any `json:"details,omitempty"`
	Field   string         `json:"field,omitempty"`
}

// Error Codes
const (
	ErrCodeValidationFailed  = "VALIDATION_FAILED"
	ErrCodeTaskBlocked       = "TASK_BLOCKED"
	ErrCodeCycleDetected     = "CYCLE_DETECTED"
	ErrCodeNotFound          = "NOT_FOUND"
	ErrCodeUnauthorized      = "UNAUTHORIZED"
	ErrCodeActiveSession     = "ACTIVE_SESSION_EXISTS"
	ErrCodeInvalidRecurrence = "INVALID_RECURRENCE"
	ErrCodeInvalidDuration   = "INVALID_DURATION"
	ErrCodeSelfDependency    = "SELF_DEPENDENCY"
)

// Helper functions
func NewErrorResponse(code, message string) ErrorResponse {
	return ErrorResponse{
		Error: ErrorDetail{
			Code:    code,
			Message: message,
		},
	}
}

func NewValidationErrorResponse(field, message string) ErrorResponse {
	return ErrorResponse{
		Error: ErrorDetail{
			Code:    ErrCodeValidationFailed,
			Message: message,
			Field:   field,
		},
	}
}
```

---

## 3. Migration Script

**Dosya:** `cmd/migrate/main.go`

```go
package main

import (
	"log"

	"github.com/ozlucodes/focusflow/internal/config"
	"github.com/ozlucodes/focusflow/internal/models"
)

func main() {
	log.Println("Starting database migration...")

	// Load config
	cfg := config.LoadConfig()

	// Init DB
	db := config.InitDB(cfg)
	config.DB = db

	// Auto migrate
	err := db.AutoMigrate(
		&models.User{},
		&models.Task{},
		&models.TaskDependency{},
		&models.Reminder{},
		&models.Tag{},
		&models.FocusSession{},
	)

	if err != nil {
		log.Fatal("Migration failed:", err)
	}

	log.Println("Migration completed successfully!")
	log.Println("Creating indexes...")

	// Create custom indexes
	createIndexes(db)

	log.Println("All done!")
}

func createIndexes(db *gorm.DB) {
	// Compound indexes
	db.Exec(`
		CREATE INDEX IF NOT EXISTS idx_tasks_status_priority
		ON tasks(status, priority)
		WHERE status != 'COMPLETED'
	`)

	db.Exec(`
		CREATE INDEX IF NOT EXISTS idx_tasks_user_due
		ON tasks(user_id, due_date)
		WHERE due_date IS NOT NULL
	`)

	db.Exec(`
		CREATE INDEX IF NOT EXISTS idx_tasks_user_status
		ON tasks(user_id, status)
	`)

	db.Exec(`
		CREATE INDEX IF NOT EXISTS idx_reminders_pending
		ON reminders(remind_at, is_sent)
		WHERE is_sent = false
	`)

	db.Exec(`
		CREATE INDEX IF NOT EXISTS idx_focus_sessions_user_status
		ON focus_sessions(user_id, started_at DESC)
		WHERE status = 'COMPLETED'
	`)

	// Unique index for dependencies
	db.Exec(`
		CREATE UNIQUE INDEX IF NOT EXISTS idx_task_dependency_unique
		ON task_dependencies(blocker_task_id, blocked_task_id)
	`)

	// Partial unique index for active focus sessions
	db.Exec(`
		CREATE UNIQUE INDEX IF NOT EXISTS idx_active_focus_session
		ON focus_sessions(user_id, status)
		WHERE status = 'RUNNING'
	`)

	log.Println("Indexes created!")
}
```

---

## 4. .env Dosyası

**Dosya:** `.env`

```env
# Supabase Database Credentials
DB_HOST=db.xxx.supabase.co
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your-supabase-db-password
DB_NAME=postgres
DB_SSLMODE=require

# JWT Secret
JWT_SECRET=your-jwt-secret-key-min-32-chars-long

# Server Port
PORT=3000

# Focus Timer Settings
DEFAULT_FOCUS_DURATION=25
```

---

## 5. Test

```bash
# Migration çalıştır
go run cmd/migrate/main.go

# Çıktı:
# Starting database migration...
# Connected to Supabase PostgreSQL successfully!
# Migration completed successfully!
# Creating indexes...
# Indexes created!
# All done!
```

---

## Checklist

- [ ] Proje yapısı oluşturuldu
- [ ] Go modül başlatıldı
- [ ] Gerekli kütüphaneler yüklendi
- [ ] `internal/config/database.go` oluşturuldu
- [ ] `internal/models/user.go` oluşturuldu
- [ ] `internal/models/task.go` oluşturuldu
- [ ] `internal/models/task_dependency.go` oluşturuldu
- [ ] `internal/models/reminder.go` oluşturuldu
- [ ] `internal/models/tag.go` oluşturuldu
- [ ] `internal/models/focus_session.go` oluşturuldu
- [ ] `internal/models/error.go` oluşturuldu
- [ ] `cmd/migrate/main.go` oluşturuldu
- [ ] `.env` dosyası yapılandırıldı
- [ ] Migration başarıyla çalıştı
- [ ] Supabase Dashboard'da tablolar doğrulandı
