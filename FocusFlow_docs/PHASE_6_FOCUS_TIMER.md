# Phase 6: Focus Timer Implementation

## Amaç
Pomodoro tarzı focus timer özelliklerini implement etmek.

---

## 1. Focus Handlers

**Dosya:** `internal/handlers/focus_handler.go`

```go
package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/ozlucodes/focusflow/internal/models"
	"github.com/ozlucodes/focusflow/internal/services"
)

type FocusHandler struct {
	focusService services.FocusService
}

func NewFocusHandler(focusService services.FocusService) *FocusHandler {
	return &FocusHandler{focusService: focusService}
}

type StartSessionRequest struct {
	TaskID   *uuid.UUID `json:"task_id,omitempty"`   // Optional - taskless session
	Duration int        `json:"duration" validate:"min=1,max=120"`
}

// StartSession starts a new focus session
// @Summary Start focus session
// @Tags focus
// @Accept json
// @Produce json
// @Param request body StartSessionRequest true "Session data"
// @Success 201 {object} models.FocusSession
// @Failure 400 {object} models.ErrorResponse
// @Router /api/focus/sessions [post]
func (h *FocusHandler) StartSession(c *fiber.Ctx) error {
	userID := c.Locals("userID").(uuid.UUID)

	var req StartSessionRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid request body",
		))
	}

	// Default duration if not provided
	if req.Duration == 0 {
		req.Duration = 25
	}

	session, err := h.focusService.StartSession(userID, req.TaskID, req.Duration)
	if err != nil {
		if errResp, ok := err.(*models.ErrorResponse); ok {
			return c.Status(400).JSON(errResp)
		}
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			err.Error(),
		))
	}

	return c.Status(201).JSON(session)
}

// GetSession returns a focus session by ID
// @Summary Get focus session
// @Tags focus
// @Produce json
// @Param id path string true "Session ID"
// @Success 200 {object} models.FocusSession
// @Failure 404 {object} models.ErrorResponse
// @Router /api/focus/sessions/{id} [get]
func (h *FocusHandler) GetSession(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid session ID",
		))
	}

	session, err := h.focusService.GetSession(id)
	if err != nil {
		return c.Status(404).JSON(models.NewErrorResponse(
			models.ErrCodeNotFound,
			"Session not found",
		))
	}

	return c.JSON(session)
}

// GetUserSessions returns all sessions for the current user
// @Summary Get user sessions
// @Tags focus
// @Produce json
// @Param status query string false "Filter by status"
// @Param task_id query string false "Filter by task ID"
// @Success 200 {array} models.FocusSession
// @Router /api/focus/sessions [get]
func (h *FocusHandler) GetUserSessions(c *fiber.Ctx) error {
	userID := c.Locals("userID").(uuid.UUID)

	filters := make(map[string]interface{})
	if status := c.Query("status"); status != "" {
		filters["status"] = status
	}
	if taskID := c.Query("task_id"); taskID != "" {
		if id, err := uuid.Parse(taskID); err == nil {
			filters["task_id"] = id
		}
	}

	sessions, err := h.focusService.GetUserSessions(userID, filters)
	if err != nil {
		return c.Status(500).JSON(models.NewErrorResponse(
			"INTERNAL_ERROR",
			err.Error(),
		))
	}

	return c.JSON(sessions)
}

// CompleteSession completes a focus session
// @Summary Complete session
// @Tags focus
// @Produce json
// @Param id path string true "Session ID"
// @Success 200 {object} models.FocusSession
// @Failure 400 {object} models.ErrorResponse
// @Router /api/focus/sessions/{id}/complete [post]
func (h *FocusHandler) CompleteSession(c *fiber.Ctx) error {
	userID := c.Locals("userID").(uuid.UUID)

	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid session ID",
		))
	}

	if err := h.focusService.CompleteSession(id, userID); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			err.Error(),
		))
	}

	session, _ := h.focusService.GetSession(id)
	return c.JSON(session)
}

// CancelSession cancels a focus session
// @Summary Cancel session
// @Tags focus
// @Produce json
// @Param id path string true "Session ID"
// @Success 200 {object} models.FocusSession
// @Failure 400 {object} models.ErrorResponse
// @Router /api/focus/sessions/{id}/cancel [post]
func (h *FocusHandler) CancelSession(c *fiber.Ctx) error {
	userID := c.Locals("userID").(uuid.UUID)

	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid session ID",
		))
	}

	if err := h.focusService.CancelSession(id, userID); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			err.Error(),
		))
	}

	session, _ := h.focusService.GetSession(id)
	return c.JSON(session)
}

// PauseSession pauses a running focus session
// @Summary Pause session
// @Tags focus
// @Produce json
// @Param id path string true "Session ID"
// @Success 200 {object} models.FocusSession
// @Failure 400 {object} models.ErrorResponse
// @Router /api/focus/sessions/{id}/pause [post]
func (h *FocusHandler) PauseSession(c *fiber.Ctx) error {
	userID := c.Locals("userID").(uuid.UUID)

	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid session ID",
		))
	}

	if err := h.focusService.PauseSession(id, userID); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			err.Error(),
		))
	}

	session, _ := h.focusService.GetSession(id)
	return c.JSON(session)
}

// ResumeSession resumes a paused focus session
// @Summary Resume session
// @Tags focus
// @Produce json
// @Param id path string true "Session ID"
// @Success 200 {object} models.FocusSession
// @Failure 400 {object} models.ErrorResponse
// @Router /api/focus/sessions/{id}/resume [post]
func (h *FocusHandler) ResumeSession(c *fiber.Ctx) error {
	userID := c.Locals("userID").(uuid.UUID)

	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid session ID",
		))
	}

	if err := h.focusService.ResumeSession(id, userID); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			err.Error(),
		))
	}

	session, _ := h.focusService.GetSession(id)
	return c.JSON(session)
}

// GetStats returns focus statistics for the user
// @Summary Get focus stats
// @Tags focus
// @Produce json
// @Success 200 {object} repository.FocusStats
// @Router /api/focus/stats [get]
func (h *FocusHandler) GetStats(c *fiber.Ctx) error {
	userID := c.Locals("userID").(uuid.UUID)

	stats, err := h.focusService.GetStats(userID)
	if err != nil {
		return c.Status(500).JSON(models.NewErrorResponse(
			"INTERNAL_ERROR",
			err.Error(),
		))
	}

	return c.JSON(stats)
}
```

---

## 2. Focus Timer Response Formats

### Session Response
```json
{
  "id": "uuid",
  "task_id": "uuid",
  "user_id": "uuid",
  "duration": 25,
  "status": "RUNNING",
  "started_at": "2024-10-24T10:00:00Z",
  "completed_at": null,
  "paused_at": null,
  "total_paused": 0,
  "created_at": "2024-10-24T10:00:00Z",
  "actual_duration": 25,
  "remaining_seconds": 1500,
  "is_paused": false
}
```

### Stats Response
```json
{
  "total_sessions": 45,
  "total_minutes": 1125,
  "completed_today": 3,
  "minutes_today": 75,
  "longest_streak": 7,
  "completed_this_week": 15,
  "average_session_length": 25,
  "most_productive_day": "Tuesday",
  "current_streak": 3
}
```

---

## 3. WebSocket for Real-time Updates (Optional)

**Dosya:** `internal/handlers/websocket_handler.go`

```go
package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/websocket/v2"
	"github.com/google/uuid"
)

type WebSocketHandler struct {
	// Hub for managing connections
	hub *Hub
}

type Hub struct {
	clients    map[*Client]bool
	broadcast  chan []byte
	register   chan *Client
	unregister chan *Client
}

type Client struct {
	ID     uuid.UUID
	UserID uuid.UUID
	Conn   *websocket.Conn
	Send   chan []byte
}

func NewWebSocketHandler() *WebSocketHandler {
	hub := &Hub{
		clients:    make(map[*Client]bool),
		broadcast:  make(chan []byte),
		register:   make(chan *Client),
		unregister: make(chan *Client),
	}

	go hub.run()

	return &WebSocketHandler{hub: hub}
}

func (h *Hub) run() {
	for {
		select {
		case client := <-h.register:
			h.clients[client] = true
		case client := <-h.unregister:
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				close(client.Send)
			}
		case message := <-h.broadcast:
			for client := range h.clients {
				select {
				case client.Send <- message:
				default:
					close(client.Send)
					delete(h.clients, client)
				}
			}
		}
	}
}

// HandleFocusSessionWS handles WebSocket connections for focus session updates
func (h *WebSocketHandler) HandleFocusSessionWS(c *websocket.Conn) {
	userID := c.Locals("userID").(uuid.UUID)

	client := &Client{
		ID:     uuid.New(),
		UserID: userID,
		Conn:   c,
		Send:   make(chan []byte, 256),
	}

	h.hub.register <- client

	defer func() {
		h.hub.unregister <- client
		c.Close()
	}()

	// Read messages from client
	go func() {
		defer c.Close()
		for {
			_, _, err := c.ReadMessage()
			if err != nil {
				break
			}
		}
	}()

	// Write messages to client
	for {
		select {
		case message, ok := <-client.Send:
			if !ok {
				return
			}
			if err := c.WriteMessage(websocket.TextMessage, message); err != nil {
				return
			}
		}
	}
}

// BroadcastSessionUpdate broadcasts session updates to all connected clients
func (h *WebSocketHandler) BroadcastSessionUpdate(sessionID uuid.UUID, update interface{}) {
	message, _ := json.Marshal(map[string]interface{}{
		"type":    "session_update",
		"session": update,
	})
	h.hub.broadcast <- message
}
```

---

## 4. Focus Timer UI Integration Points

### Flutter/Client Integration

```dart
// Focus Session Model
class FocusSession {
  final String id;
  final String? taskId;
  final int duration;
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime? pausedAt;
  final int totalPaused;

  int get remainingSeconds {
    if (completedAt != null) return 0;
    if (pausedAt != null) {
      // Calculate based on pausedAt
    }
    // Calculate based on startedAt
  }

  bool get isRunning => status == 'RUNNING';
  bool get isPaused => status == 'PAUSED';
  bool get isCompleted => status == 'COMPLETED';

  double get progress {
    if (completedAt != null) return 1.0;
    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    return elapsed / (duration * 60);
  }
}

// API Calls
class FocusAPI {
  Future<FocusSession> startSession({String? taskId, int duration = 25}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/focus/sessions'),
      headers: {'Authorization': 'Bearer $token'},
      body: jsonEncode({
        if (taskId != null) 'task_id': taskId,
        'duration': duration,
      }),
    );
    return FocusSession.fromJson(jsonDecode(response.body));
  }

  Future<FocusSession> pauseSession(String sessionId) async {
    // ...
  }

  Future<FocusSession> resumeSession(String sessionId) async {
    // ...
  }

  Future<FocusSession> completeSession(String sessionId) async {
    // ...
  }
}
```

---

## Checklist

- [ ] `internal/handlers/focus_handler.go` oluşturuldu
- [ ] Focus service Phase 3'te oluşturuldu
- [ ] Pause/Resume mekanizması test edildi
- [ ] Active session kontrolü çalışıyor
- [ ] Duration validation (1-120 dakika) çalışıyor
- [ ] Stats hesaplaması doğru çalışıyor
- [ ] WebSocket handler (opsiyonel) oluşturuldu
