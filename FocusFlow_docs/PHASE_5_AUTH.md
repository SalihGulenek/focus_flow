# Phase 5: Authentication & JWT

## Amaç
JWT tabanlı authentication sistemini implement etmek.

---

## 1. Auth Middleware

**Dosya:** `internal/middleware/auth.go`

```go
package middleware

import (
	"errors"
	"os"
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

var jwtSecret = []byte(os.Getenv("JWT_SECRET"))

// Claims represents JWT claims
type Claims struct {
	UserID uuid.UUID `json:"user_id"`
	Email  string    `json:"email"`
	jwt.RegisteredClaims
}

// AuthMiddleware validates JWT tokens
func AuthMiddleware() fiber.Handler {
	return func(c *fiber.Ctx) error {
		authHeader := c.Get("Authorization")
		if authHeader == "" {
			return c.Status(401).JSON(fiber.Map{
				"error": fiber.Map{
					"code":    "MISSING_TOKEN",
					"message": "Authorization header required",
				},
			})
		}

		// Extract token from "Bearer <token>"
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			return c.Status(401).JSON(fiber.Map{
				"error": fiber.Map{
					"code":    "INVALID_TOKEN_FORMAT",
					"message": "Invalid authorization format",
				},
			})
		}

		tokenString := parts[1]

		// Parse and validate token
		token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, errors.New("unexpected signing method")
			}
			return jwtSecret, nil
		})

		if err != nil || !token.Valid {
			return c.Status(401).JSON(fiber.Map{
				"error": fiber.Map{
					"code":    "INVALID_TOKEN",
					"message": "Invalid or expired token",
				},
			})
		}

		// Extract claims
		if claims, ok := token.Claims.(*Claims); ok {
			c.Locals("userID", claims.UserID)
			c.Locals("email", claims.Email)
		}

		return c.Next()
	}
}

// OptionalAuthMiddleware checks for token but doesn't require it
func OptionalAuthMiddleware() fiber.Handler {
	return func(c *fiber.Ctx) error {
		authHeader := c.Get("Authorization")
		if authHeader == "" {
			return c.Next()
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) == 2 && parts[0] == "Bearer" {
			tokenString := parts[1]
			token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
				return jwtSecret, nil
			})

			if err == nil && token.Valid {
				if claims, ok := token.Claims.(*Claims); ok {
					c.Locals("userID", claims.UserID)
					c.Locals("email", claims.Email)
				}
			}
		}

		return c.Next()
	}
}

// GenerateToken creates a new JWT token
func GenerateToken(userID uuid.UUID, email string) (string, error) {
	claims := &Claims{
		UserID: userID,
		Email:  email,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Issuer:    "focusflow",
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(jwtSecret)
}

// GenerateRefreshToken creates a new refresh token (longer lived)
func GenerateRefreshToken(userID uuid.UUID) (string, error) {
	claims := &Claims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(30 * 24 * time.Hour)), // 30 days
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Issuer:    "focusflow",
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(jwtSecret)
}

// ValidateToken validates a JWT token and returns claims
func ValidateToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		return jwtSecret, nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, errors.New("invalid token")
}
```

---

## 2. Auth Service

**Dosya:** `internal/services/auth_service.go`

```go
package services

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/ozlucodes/focusflow/internal/models"
	"github.com/ozlucodes/focusflow/internal/repository"
	"github.com/ozlucodes/focusflow/internal/middleware"
	"golang.org/x/crypto/bcrypt"
)

type AuthService interface {
	Register(email, password, fullName string) (*models.User, error)
	Login(email, password string) (*AuthResponse, error)
	RefreshToken(refreshToken string) (*AuthResponse, error)
	Logout(userID uuid.UUID, token string) error
	GetUserByID(id uuid.UUID) (*models.User, error)
	UpdateProfile(userID uuid.UUID, updates map[string]interface{}) error
	ChangePassword(userID uuid.UUID, oldPassword, newPassword string) error
}

type authService struct {
	userRepo   repository.UserRepository
	redis      *redis.Client // For refresh token storage
}

type AuthResponse struct {
	User         *models.User `json:"user"`
	AccessToken  string       `json:"access_token"`
	RefreshToken string       `json:"refresh_token"`
	ExpiresIn    int          `json:"expires_in"` // seconds
}

type RegisterRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required,min=8,max=72"`
	FullName string `json:"full_name" validate:"required,min=1,max=100"`
}

type LoginRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required"`
}

type ChangePasswordRequest struct {
	OldPassword string `json:"old_password" validate:"required"`
	NewPassword string `json:"new_password" validate:"required,min=8,max=72"`
}

func NewAuthService(
	userRepo repository.UserRepository,
	redisClient *redis.Client,
) AuthService {
	return &authService{
		userRepo: userRepo,
		redis:    redisClient,
	}
}

func (s *authService) Register(email, password, fullName string) (*models.User, error) {
	// Check if user exists
	existing, _ := s.userRepo.GetByEmail(email)
	if existing != nil {
		return nil, &models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    "EMAIL_EXISTS",
				Message: "User with this email already exists",
			},
		}
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	user := &models.User{
		ID:           uuid.New(),
		Email:        email,
		PasswordHash: string(hashedPassword),
		FullName:     fullName,
		Timezone:     "Europe/Istanbul",
	}

	if err := s.userRepo.Create(user); err != nil {
		return nil, err
	}

	// Don't return password hash
	user.PasswordHash = ""
	return user, nil
}

func (s *authService) Login(email, password string) (*AuthResponse, error) {
	user, err := s.userRepo.GetByEmail(email)
	if err != nil {
		return nil, &models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    models.ErrCodeUnauthorized,
				Message: "Invalid email or password",
			},
		}
	}

	// Verify password
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)); err != nil {
		return nil, &models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    models.ErrCodeUnauthorized,
				Message: "Invalid email or password",
			},
		}
	}

	// Generate tokens
	accessToken, _ := middleware.GenerateToken(user.ID, user.Email)
	refreshToken, _ := middleware.GenerateRefreshToken(user.ID)

	// Store refresh token in Redis (optional)
	if s.redis != nil {
		key := fmt.Sprintf("refresh_token:%s", user.ID.String())
		s.redis.Set(ctx, key, refreshToken, 30*24*time.Hour)
	}

	// Don't return password hash
	user.PasswordHash = ""

	return &AuthResponse{
		User:         user,
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    24 * 60 * 60, // 24 hours in seconds
	}, nil
}

func (s *authService) RefreshToken(refreshToken string) (*AuthResponse, error) {
	// Validate refresh token
	claims, err := middleware.ValidateToken(refreshToken)
	if err != nil {
		return nil, &models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    models.ErrCodeUnauthorized,
				Message: "Invalid refresh token",
			},
		}
	}

	// Check if token exists in Redis (if using Redis)
	if s.redis != nil {
		key := fmt.Sprintf("refresh_token:%s", claims.UserID.String())
		storedToken, _ := s.redis.Get(ctx, key).Result()
		if storedToken != refreshToken {
			return nil, &models.ErrorResponse{
				Error: models.ErrorDetail{
					Code:    models.ErrCodeUnauthorized,
					Message: "Refresh token revoked",
				},
			}
		}
	}

	// Get user
	user, err := s.userRepo.GetByID(claims.UserID)
	if err != nil {
		return nil, &models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    models.ErrCodeNotFound,
				Message: "User not found",
			},
		}
	}

	// Generate new tokens
	accessToken, _ := middleware.GenerateToken(user.ID, user.Email)
	newRefreshToken, _ := middleware.GenerateRefreshToken(user.ID)

	// Update refresh token in Redis
	if s.redis != nil {
		key := fmt.Sprintf("refresh_token:%s", user.ID.String())
		s.redis.Set(ctx, key, newRefreshToken, 30*24*time.Hour)
	}

	user.PasswordHash = ""

	return &AuthResponse{
		User:         user,
		AccessToken:  accessToken,
		RefreshToken: newRefreshToken,
		ExpiresIn:    24 * 60 * 60,
	}, nil
}

func (s *authService) Logout(userID uuid.UUID, token string) error {
	// Remove refresh token from Redis
	if s.redis != nil {
		key := fmt.Sprintf("refresh_token:%s", userID.String())
		s.redis.Del(ctx, key)
	}

	// Optionally: Add access token to blacklist
	return nil
}

func (s *authService) GetUserByID(id uuid.UUID) (*models.User, error) {
	user, err := s.userRepo.GetByID(id)
	if err != nil {
		return nil, &models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    models.ErrCodeNotFound,
				Message: "User not found",
			},
		}
	}

	user.PasswordHash = ""
	return user, nil
}

func (s *authService) UpdateProfile(userID uuid.UUID, updates map[string]interface{}) error {
	user, err := s.userRepo.GetByID(userID)
	if err != nil {
		return err
	}

	if fullName, ok := updates["full_name"]; ok {
		user.FullName = fullName.(string)
	}
	if avatarURL, ok := updates["avatar_url"]; ok {
		user.AvatarURL = avatarURL.(string)
	}
	if timezone, ok := updates["timezone"]; ok {
		user.Timezone = timezone.(string)
	}

	return s.userRepo.Update(user)
}

func (s *authService) ChangePassword(userID uuid.UUID, oldPassword, newPassword string) error {
	user, err := s.userRepo.GetByID(userID)
	if err != nil {
		return err
	}

	// Verify old password
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(oldPassword)); err != nil {
		return &models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    "INVALID_PASSWORD",
				Message: "Current password is incorrect",
			},
		}
	}

	// Hash new password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	user.PasswordHash = string(hashedPassword)
	return s.userRepo.Update(user)
}
```

---

## 3. Auth Handlers

**Dosya:** `internal/handlers/auth_handler.go`

```go
package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/ozlucodes/focusflow/internal/models"
	"github.com/ozlucodes/focusflow/internal/services"
)

type AuthHandler struct {
	authService services.AuthService
}

func NewAuthHandler(authService services.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

// Register registers a new user
// @Summary Register
// @Tags auth
// @Accept json
// @Produce json
// @Param request body services.RegisterRequest true "Register data"
// @Success 201 {object} services.AuthResponse
// @Failure 400 {object} models.ErrorResponse
// @Router /api/auth/register [post]
func (h *AuthHandler) Register(c *fiber.Ctx) error {
	var req services.RegisterRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid request body",
		))
	}

	user, err := h.authService.Register(req.Email, req.Password, req.FullName)
	if err != nil {
		if errResp, ok := err.(*models.ErrorResponse); ok {
			return c.Status(400).JSON(errResp)
		}
		return c.Status(500).JSON(models.NewErrorResponse(
			"INTERNAL_ERROR",
			err.Error(),
		))
	}

	// Auto-login after registration
	authResp, _ := h.authService.Login(req.Email, req.Password)
	return c.Status(201).JSON(authResp)
}

// Login logs in a user
// @Summary Login
// @Tags auth
// @Accept json
// @Produce json
// @Param request body services.LoginRequest true "Login data"
// @Success 200 {object} services.AuthResponse
// @Failure 401 {object} models.ErrorResponse
// @Router /api/auth/login [post]
func (h *AuthHandler) Login(c *fiber.Ctx) error {
	var req services.LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid request body",
		))
	}

	authResp, err := h.authService.Login(req.Email, req.Password)
	if err != nil {
		if errResp, ok := err.(*models.ErrorResponse); ok {
			return c.Status(401).JSON(errResp)
		}
		return c.Status(401).JSON(models.NewErrorResponse(
			models.ErrCodeUnauthorized,
			"Login failed",
		))
	}

	return c.JSON(authResp)
}

// RefreshToken refreshes an access token
// @Summary Refresh token
// @Tags auth
// @Accept json
// @Produce json
// @Param request body map{refresh_token: string} true "Refresh token"
// @Success 200 {object} services.AuthResponse
// @Failure 401 {object} models.ErrorResponse
// @Router /api/auth/refresh [post]
func (h *AuthHandler) RefreshToken(c *fiber.Ctx) error {
	var req struct {
		RefreshToken string `json:"refresh_token" validate:"required"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid request body",
		))
	}

	authResp, err := h.authService.RefreshToken(req.RefreshToken)
	if err != nil {
		if errResp, ok := err.(*models.ErrorResponse); ok {
			return c.Status(401).JSON(errResp)
		}
		return c.Status(401).JSON(models.NewErrorResponse(
			models.ErrCodeUnauthorized,
			"Token refresh failed",
		))
	}

	return c.JSON(authResp)
}

// Logout logs out a user
// @Summary Logout
// @Tags auth
// @Produce json
// @Success 200
// @Router /api/auth/logout [post]
func (h *AuthHandler) Logout(c *fiber.Ctx) error {
	userID := c.Locals("userID").(uuid.UUID)
	token := c.Get("Authorization")

	if err := h.authService.Logout(userID, token); err != nil {
		return c.Status(500).JSON(models.NewErrorResponse(
			"INTERNAL_ERROR",
			"Logout failed",
		))
	}

	return c.JSON(fiber.Map{"message": "Logged out successfully"})
}

// GetMe returns the current user
// @Summary Get current user
// @Tags auth
// @Produce json
// @Success 200 {object} models.User
// @Failure 401 {object} models.ErrorResponse
// @Router /api/auth/me [get]
func (h *AuthHandler) GetMe(c *fiber.Ctx) error {
	userID := c.Locals("userID").(uuid.UUID)

	user, err := h.authService.GetUserByID(userID)
	if err != nil {
		if errResp, ok := err.(*models.ErrorResponse); ok {
			return c.Status(404).JSON(errResp)
		}
		return c.Status(500).JSON(models.NewErrorResponse(
			"INTERNAL_ERROR",
			err.Error(),
		))
	}

	return c.JSON(user)
}

// UpdateProfile updates the user's profile
// @Summary Update profile
// @Tags auth
// @Accept json
// @Produce json
// @Param request body map{full_name, avatar_url, timezone} true "Profile data"
// @Success 200 {object} models.User
// @Failure 400 {object} models.ErrorResponse
// @Router /api/auth/profile [put]
func (h *AuthHandler) UpdateProfile(c *fiber.Ctx) error {
	userID := c.Locals("userID").(uuid.UUID)

	var updates map[string]interface{}
	if err := c.BodyParser(&updates); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid request body",
		))
	}

	if err := h.authService.UpdateProfile(userID, updates); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			err.Error(),
		))
	}

	user, _ := h.authService.GetUserByID(userID)
	return c.JSON(user)
}

// ChangePassword changes the user's password
// @Summary Change password
// @Tags auth
// @Accept json
// @Produce json
// @Param request body services.ChangePasswordRequest true "Password data"
// @Success 200
// @Failure 400 {object} models.ErrorResponse
// @Router /api/auth/password [put]
func (h *AuthHandler) ChangePassword(c *fiber.Ctx) error {
	userID := c.Locals("userID").(uuid.UUID)

	var req services.ChangePasswordRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid request body",
		))
	}

	if err := h.authService.ChangePassword(userID, req.OldPassword, req.NewPassword); err != nil {
		if errResp, ok := err.(*models.ErrorResponse); ok {
			return c.Status(400).JSON(errResp)
		}
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			err.Error(),
		))
	}

	return c.JSON(fiber.Map{"message": "Password changed successfully"})
}
```

---

## Checklist

- [ ] `internal/middleware/auth.go` oluşturuldu
- [ ] `internal/services/auth_service.go` oluşturuldu
- [ ] `internal/handlers/auth_handler.go` oluşturuldu
- [ ] JWT token generation çalışıyor
- [ ] Password hashing çalışıyor
- [ ] Refresh token mekanizması çalışıyor
- [ ] Logout çalışıyor
