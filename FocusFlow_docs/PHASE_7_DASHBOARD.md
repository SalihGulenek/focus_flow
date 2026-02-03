# Phase 7: Main Application & Routes

## Amaç
Tüm bileşenleri bir araya getirip ana uygulamayı oluşturmak.

---

## 1. Main Application

**Dosya:** `main.go`

```go
package main

import (
	"fmt"
	"log"
	"os"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/limiter"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/joho/godotenv"
	"github.com/ozlucodes/focusflow/internal/config"
	"github.com/ozlucodes/focusflow/internal/handlers"
	"github.com/ozlucodes/focusflow/internal/middleware"
	"github.com/ozlucodes/focusflow/internal/repository"
	"github.com/ozlucodes/focusflow/internal/services"
	"github.com/redis/go-redis/v9"
)

func main() {
	// Load .env
	godotenv.Load()

	// Load config
	cfg := config.LoadConfig()

	// Init database
	db := config.InitDB(cfg)
	config.DB = db

	// Init Redis (optional)
	var rdb *redis.Client
	if redisAddr := os.Getenv("REDIS_ADDR"); redisAddr != "" {
		rdb = redis.NewClient(&redis.Options{
			Addr:     redisAddr,
			Password: os.Getenv("REDIS_PASSWORD"),
			DB:       0,
		})
	}

	// Init repositories
	userRepo := repository.NewUserRepository(db)
	taskRepo := repository.NewTaskRepository(db)
	dependencyRepo := repository.NewDependencyRepository(db)
	reminderRepo := repository.NewReminderRepository(db)
	tagRepo := repository.NewTagRepository(db)
	focusRepo := repository.NewFocusRepository(db)

	// Init services
	authService := services.NewAuthService(userRepo, rdb)
	taskService := services.NewTaskService(taskRepo, dependencyRepo, nil, db) // FlowService injected later
	flowService := services.NewFlowService(dependencyRepo, taskRepo)
	focusService := services.NewFocusService(focusRepo, taskRepo, db)
	dashboardService := services.NewDashboardService(taskRepo, focusRepo)

	// Update taskService with flowService
	taskService = services.NewTaskService(taskRepo, dependencyRepo, flowService, db)

	// Init handlers
	authHandler := handlers.NewAuthHandler(authService)
	taskHandler := handlers.NewTaskHandler(taskService)
	dependencyHandler := handlers.NewDependencyHandler(flowService)
	dashboardHandler := handlers.NewDashboardHandler(dashboardService)
	tagHandler := handlers.NewTagHandler(tagRepo)
	focusHandler := handlers.NewFocusHandler(focusService)
	wsHandler := handlers.NewWebSocketHandler()

	// Create Fiber app
	app := fiber.New(fiber.Config{
		AppName:      "FocusFlow API v1.0",
		ServerHeader: "FocusFlow",
		ErrorHandler: customErrorHandler,
	})

	// Middleware
	app.Use(recover.New())
	app.Use(logger.New())
	app.Use(cors.New(cors.Config{
		AllowOrigins:     os.Getenv("CORS_ALLOWED_ORIGINS"),
		AllowCredentials: true,
		AllowHeaders:     "Origin, Content-Type, Accept, Authorization",
	}))

	// Rate limiting
	app.Use(limiter.New(limiter.Config{
		Max:        100,
		Expiration: 1 * time.Hour,
		KeyGenerator: func(c *fiber.Ctx) string {
			return c.Get("X-Forwarded-For")
		},
		LimitReached: func(c *fiber.Ctx) error {
			return c.Status(429).JSON(fiber.Map{
				"error": fiber.Map{
					"code":    "RATE_LIMIT_EXCEEDED",
					"message": "Too many requests, please try again later",
				},
			})
		},
	}))

	// Health check
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status": "ok",
			"version": "1.0.0",
		})
	})

	// Setup routes
	setupRoutes(app, authHandler, taskHandler, dependencyHandler, dashboardHandler, tagHandler, focusHandler, wsHandler)

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	log.Printf("Server starting on port %s...", port)
	if err := app.Listen(":" + port); err != nil {
		log.Fatal(err)
	}
}

func setupRoutes(
	app *fiber.App,
	authHandler *handlers.AuthHandler,
	taskHandler *handlers.TaskHandler,
	dependencyHandler *handlers.DependencyHandler,
	dashboardHandler *handlers.DashboardHandler,
	tagHandler *handlers.TagHandler,
	focusHandler *handlers.FocusHandler,
	wsHandler *handlers.WebSocketHandler,
) {
	api := app.Group("/api")

	// Auth routes (public)
	auth := api.Group("/auth")
	auth.Post("/register", authHandler.Register)
	auth.Post("/login", authHandler.Login)
	auth.Post("/refresh", authHandler.RefreshToken)

	// Auth routes (protected)
	auth.Use(middleware.AuthMiddleware())
	auth.Post("/logout", authHandler.Logout)
	auth.Get("/me", authHandler.GetMe)
	auth.Put("/profile", authHandler.UpdateProfile)
	auth.Put("/password", authHandler.ChangePassword)

	// Protected routes
	protected := api.Group("")
	protected.Use(middleware.AuthMiddleware())

	// Dashboard
	protected.Get("/dashboard", dashboardHandler.GetDashboard)
	protected.Get("/dashboard/stats", dashboardHandler.GetStats)
	protected.Get("/dashboard/today", dashboardHandler.GetTodayTasks)

	// Tasks
	tasks := protected.Group("/tasks")
	tasks.Get("/", taskHandler.GetTasks)
	tasks.Post("/", taskHandler.CreateTask)
	tasks.Get("/:id", taskHandler.GetTaskByID)
	tasks.Put("/:id", taskHandler.UpdateTask)
	tasks.Delete("/:id", taskHandler.DeleteTask)
	tasks.Post("/:id/complete", taskHandler.CompleteTask)
	tasks.Post("/:id/activate", taskHandler.ActivateTask)

	// Subtasks
	tasks.Get("/:id/subtasks", taskHandler.GetSubtasks)
	tasks.Post("/:id/subtasks", taskHandler.CreateSubtask)
	tasks.Put("/:id/subtasks/:sub_id", taskHandler.UpdateSubtask)
	tasks.Delete("/:id/subtasks/:sub_id", taskHandler.DeleteSubtask)
	tasks.Post("/:id/subtasks/:sub_id/complete", taskHandler.CompleteSubtask)

	// Dependencies/Flow
	tasks.Get("/:id/dependencies", dependencyHandler.GetDependencies)
	tasks.Post("/:id/dependencies", dependencyHandler.AddDependency)
	tasks.Delete("/:id/dependencies/:dep_id", dependencyHandler.RemoveDependency)
	tasks.Get("/:id/flow", dependencyHandler.GetFlowChain)
	tasks.Get("/:id/blocked-by", dependencyHandler.GetBlockedBy)
	tasks.Get("/:id/blocks", dependencyHandler.GetBlocks)

	// Tags
	protected.Get("/tags", tagHandler.GetTags)
	protected.Post("/tags", tagHandler.CreateTag)
	tasks.Post("/:id/tags/:tag_id", tagHandler.AssignTagToTask)
	tasks.Delete("/:id/tags/:tag_id", tagHandler.RemoveTagFromTask)

	// Focus Timer
	focus := protected.Group("/focus")
	focus.Post("/sessions", focusHandler.StartSession)
	focus.Get("/sessions", focusHandler.GetUserSessions)
	focus.Get("/sessions/:id", focusHandler.GetSession)
	focus.Post("/sessions/:id/complete", focusHandler.CompleteSession)
	focus.Post("/sessions/:id/cancel", focusHandler.CancelSession)
	focus.Post("/sessions/:id/pause", focusHandler.PauseSession)
	focus.Post("/sessions/:id/resume", focusHandler.ResumeSession)
	focus.Get("/stats", focusHandler.GetStats)

	// WebSocket (upgrade)
	protected.Get("/ws", websocket.New(wsHandler.HandleFocusSessionWS))
}

func customErrorHandler(c *fiber.Ctx, err error) error {
	code := fiber.StatusInternalServerError

	if e, ok := err.(*fiber.Error); ok {
		code = e.Code
	}

	return c.Status(code).JSON(fiber.Map{
		"error": fiber.Map{
			"code":    "INTERNAL_ERROR",
			"message": err.Error(),
		},
	})
}
```

---

## 2. CORS Configuration

**Dosya:** `internal/middleware/cors.go`

```go
package middleware

import (
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
)

func CORSConfig() cors.Config {
	return cors.Config{
		AllowOrigins:     getEnv("CORS_ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:8080"),
		AllowMethods:     "GET,POST,PUT,DELETE,OPTIONS",
		AllowHeaders:     "Origin, Content-Type, Accept, Authorization, X-Request-ID",
		AllowCredentials: true,
		MaxAge:           86400, // 24 hours
	}
}

func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
```

---

## 3. Request Validation Middleware

**Dosya:** `internal/middleware/validation.go`

```go
package middleware

import (
	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
)

var validate = validator.New()

// ValidateBody validates request body against a struct
func ValidateBody(schema interface{}) fiber.Handler {
	return func(c *fiber.Ctx) error {
		if err := c.BodyParser(schema); err != nil {
			return c.Status(400).JSON(fiber.Map{
				"error": fiber.Map{
					"code":    "INVALID_BODY",
					"message": "Invalid request body",
				},
			})
		}

		if err := validate.Struct(schema); err != nil {
			errors := err.(validator.ValidationErrors)
			messages := make([]string, 0, len(errors))

			for _, e := range errors {
				switch e.Tag() {
				case "required":
					messages = append(messages, fmt.Sprintf("%s is required", e.Field()))
				case "email":
					messages = append(messages, fmt.Sprintf("%s must be a valid email", e.Field()))
				case "min":
					messages = append(messages, fmt.Sprintf("%s must be at least %s characters", e.Field(), e.Param()))
				case "max":
					messages = append(messages, fmt.Sprintf("%s must be at most %s characters", e.Field(), e.Param()))
				default:
					messages = append(messages, fmt.Sprintf("%s validation failed", e.Field()))
				}
			}

			return c.Status(400).JSON(fiber.Map{
				"error": fiber.Map{
					"code":    models.ErrCodeValidationFailed,
					"message": messages[0],
					"details": fiber.Map{"fields": messages},
				},
			})
		}

		return c.Next()
	}
}
```

---

## 4. Rate Limiting by User

**Dosya:** `internal/middleware/rate_limit.go`

```go
package middleware

import (
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/limiter"
	"github.com/google/uuid"
)

// UserRateLimiter creates a rate limiter that uses user ID from JWT
func UserRateLimiter(max int, expiration time.Duration) fiber.Handler {
	return limiter.New(limiter.Config{
		Max:        max,
		Expiration: expiration,
		KeyGenerator: func(c *fiber.Ctx) string {
			// Try to get user ID from locals (set by auth middleware)
			if userID, ok := c.Locals("userID").(uuid.UUID); ok {
				return userID.String()
			}
			// Fallback to IP
			return c.IP()
		},
		LimitReached: func(c *fiber.Ctx) error {
			return c.Status(429).JSON(fiber.Map{
				"error": fiber.Map{
					"code":    "RATE_LIMIT_EXCEEDED",
					"message": "Too many requests, please try again later",
				},
			})
		},
	})
}
```

---

## 5. Logger Middleware

**Dosya:** `internal/middleware/logger.go`

```go
package middleware

import (
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

// RequestLogger logs HTTP requests with request ID
func RequestLogger() fiber.Handler {
	return func(c *fiber.Ctx) error {
		// Generate request ID
		reqID := uuid.New().String()
		c.Locals("reqID", reqID)
		c.Set("X-Request-ID", reqID)

		// Start time
		start := time.Now()

		// Process request
		err := c.Next()

		// Log request
		duration := time.Since(start)

		// Skip logging for health check
		if c.Path() == "/health" {
			return err
		}

		log.Printf(
			"[%s] %s %s - %d - %v - %s",
			reqID[:8],
			c.Method(),
			c.Path(),
			c.Response().StatusCode(),
			duration,
			c.IP(),
		)

		return err
	}
}
```

---

## 6. Complete .env File

**Dosya:** `.env`

```env
# Server
PORT=3000
ENV=production

# Database
DB_HOST=db.xxx.supabase.co
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your-supabase-db-password
DB_NAME=postgres
DB_SSLMODE=require

# JWT
JWT_SECRET=your-jwt-secret-key-minimum-32-characters-long

# CORS
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com

# Redis (optional)
REDIS_ADDR=localhost:6379
REDIS_PASSWORD=
REDIS_DB=0

# Rate Limiting
RATE_LIMIT_MAX=100
RATE_LIMIT_EXPIRATION=1h

# Focus Timer Defaults
DEFAULT_FOCUS_DURATION=25
MAX_FOCUS_DURATION=120
MIN_FOCUS_DURATION=1
```

---

## 7. Makefile for Development

**Dosya:** `Makefile`

```makefile
.PHONY: run build migrate test clean

# Run the application
run:
	go run main.go

# Build the application
build:
	go build -o bin/focusflow main.go

# Run migrations
migrate:
	go run cmd/migrate/main.go

# Run tests
test:
	go test -v ./...

# Run tests with coverage
test-coverage:
	go test -v -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

# Install dependencies
deps:
	go mod download
	go mod tidy

# Clean build artifacts
clean:
	rm -rf bin/
	rm -f coverage.out coverage.html

# Run with hot reload (requires air)
dev:
	air

# Docker build
docker-build:
	docker build -t focusflow:latest .

# Docker run
docker-run:
	docker run -p 3000:3000 --env-file .env focusflow:latest
```

---

## Checklist

- [ ] `main.go` oluşturuldu
- [ ] Tüm middleware'ler oluşturuldu
- [ ] Routes tanımlandı
- [ ] CORS yapılandırıldı
- [ ] Rate limiting yapılandırıldı
- [ ] Request ID logging eklendi
- [ ] Error handler oluşturuldu
- [ ] Makefile oluşturuldu
- [ ] `.env` dosyası tamamlandı
- [ ] Health check endpoint'i çalışıyor
- [ ] Tüm endpoint'ler test edildi

---

## Testing the Application

### Manual API Test Commands

```bash
# 1. Register a user
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "full_name": "Test User"
  }'

# 2. Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# 3. Create a task (replace TOKEN with actual token)
curl -X POST http://localhost:3000/api/tasks \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Task",
    "description": "This is a test task",
    "priority": 2
  }'

# 4. Get dashboard
curl -X GET http://localhost:3000/api/dashboard \
  -H "Authorization: Bearer TOKEN"

# 5. Start focus session
curl -X POST http://localhost:3000/api/focus/sessions \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "task_id": "TASK_ID",
    "duration": 25
  }'

# 6. Add dependency
curl -X POST http://localhost:3000/api/tasks/TASK2_ID/dependencies \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "blocker_task_id": "TASK1_ID"
  }'

# 7. Get flow chain
curl -X GET http://localhost:3000/api/tasks/TASK_ID/flow \
  -H "Authorization: Bearer TOKEN"
```

---

## Production Deployment Checklist

- [ ] Environment variables configured
- [ ] Database migrations run
- [ ] JWT secret is strong and unique
- [ ] CORS origins properly set
- [ ] Rate limiting enabled
- [ ] SSL/TLS configured
- [ ] Logging configured for production
- [ ] Health check endpoint working
- [ ] Graceful shutdown implemented
- [ ] Database connection pooling configured
- [ ] Redis configured (if used)
- [ ] Monitoring/alerting setup
