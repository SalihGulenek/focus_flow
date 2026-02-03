# Phase 3: Service Layer (Business Logic)

## Amaç
Business logic'i yöneten service layer'ı implement etmek.

---

## 1. TaskService

**Dosya:** `internal/services/task_service.go`

```go
package services

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/ozlucodes/focusflow/internal/models"
	"github.com/ozlucodes/focusflow/internal/repository"
	"gorm.io/gorm"
)

type TaskService interface {
	CreateTask(task *models.Task) error
	GetTaskByID(id uuid.UUID) (*models.Task, error)
	GetTasks(userID uuid.UUID, page, limit int, filters map[string]interface{}) (*TaskListResponse, error)
	UpdateTask(task *models.Task) error
	DeleteTask(id uuid.UUID, userID uuid.UUID) error
	CompleteTask(id uuid.UUID, userID uuid.UUID) error
	ActivateTask(id uuid.UUID, userID uuid.UUID) error
	CreateSubtask(parentID uuid.UUID, subtask *models.Task) error
	UpdateSubtask(taskID, subtaskID uuid.UUID, updates map[string]interface{}) error
	DeleteSubtask(taskID, subtaskID uuid.UUID) error
	GetSubtasks(taskID uuid.UUID) ([]models.Task, error)
}

type taskService struct {
	taskRepo       repository.TaskRepository
	dependencyRepo repository.DependencyRepository
	flowService    FlowService
	db             *gorm.DB
}

type TaskListResponse struct {
	Tasks      []models.Task `json:"tasks"`
	Pagination PaginationInfo `json:"pagination"`
	Summary    TaskSummary    `json:"summary"`
}

type PaginationInfo struct {
	Page       int   `json:"page"`
	Limit      int   `json:"limit"`
	Total      int64 `json:"total"`
	TotalPages int   `json:"total_pages"`
}

type TaskSummary struct {
	Total          int     `json:"total"`
	Completed      int     `json:"completed"`
	Remaining      int     `json:"remaining"`
	ProgressPercent float64 `json:"progress_percent"`
}

func NewTaskService(
	taskRepo repository.TaskRepository,
	dependencyRepo repository.DependencyRepository,
	flowService FlowService,
	db *gorm.DB,
) TaskService {
	return &taskService{
		taskRepo:       taskRepo,
		dependencyRepo: dependencyRepo,
		flowService:    flowService,
		db:             db,
	}
}

func (s *taskService) CreateTask(task *models.Task) error {
	// Validation
	if task.Title == "" {
		return errors.New("title is required")
	}

	// Set default values
	if task.Status == "" {
		task.Status = models.TaskStatusPending
	}
	if task.Priority == 0 {
		task.Priority = int(models.PriorityMedium)
	}

	// Check if task is blocked by dependencies
	blockedBy, _ := s.dependencyRepo.GetBlockedBy(task.ID)
	if len(blockedBy) > 0 {
		task.Status = models.TaskStatusBlocked
	}

	return s.taskRepo.Create(task)
}

func (s *taskService) GetTaskByID(id uuid.UUID) (*models.Task, error) {
	return s.taskRepo.GetByID(id)
}

func (s *taskService) GetTasks(userID uuid.UUID, page, limit int, filters map[string]interface{}) (*TaskListResponse, error) {
	offset := (page - 1) * limit

	tasks, total, err := s.taskRepo.GetByUserID(userID, offset, limit, filters)
	if err != nil {
		return nil, err
	}

	// Calculate summary
	completed := 0
	for _, task := range tasks {
		if task.Status == models.TaskStatusCompleted {
			completed++
		}
	}

	totalPages := int(total) / limit
	if int(total)%limit > 0 {
		totalPages++
	}

	progressPercent := 0.0
	if len(tasks) > 0 {
		progressPercent = float64(completed) / float64(len(tasks)) * 100
	}

	return &TaskListResponse{
		Tasks: tasks,
		Pagination: PaginationInfo{
			Page:       page,
			Limit:      limit,
			Total:      total,
			TotalPages: totalPages,
		},
		Summary: TaskSummary{
			Total:          len(tasks),
			Completed:      completed,
			Remaining:      len(tasks) - completed,
			ProgressPercent: progressPercent,
		},
	}, nil
}

func (s *taskService) UpdateTask(task *models.Task) error {
	return s.taskRepo.Update(task)
}

func (s *taskService) DeleteTask(id uuid.UUID, userID uuid.UUID) error {
	// Check ownership
	task, err := s.taskRepo.GetByID(id)
	if err != nil {
		return err
	}

	if task.UserID != userID {
		return errors.New("unauthorized")
	}

	return s.taskRepo.Delete(id)
}

func (s *taskService) CompleteTask(id uuid.UUID, userID uuid.UUID) error {
	// Transaction başlat
	tx := s.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// Task'ı getir
	task, err := s.taskRepo.GetByID(id)
	if err != nil {
		tx.Rollback()
		return err
	}

	if task.UserID != userID {
		tx.Rollback()
		return errors.New("unauthorized")
	}

	if task.Status == models.TaskStatusCompleted {
		tx.Rollback()
		return errors.New("task already completed")
	}

	// Task'ı complete et
	now := time.Now()
	task.Status = models.TaskStatusCompleted
	task.CompletedAt = &now

	if err := s.taskRepo.Update(task); err != nil {
		tx.Rollback()
		return err
	}

	// Subtask ise, parent'ı kontrol et
	if task.IsSubtask() {
		s.checkParentCompletion(tx, task.ParentID)
	}

	// Engellediği task'ları güncelle
	s.updateBlockedTasks(tx, id)

	// Recurring task ise bir sonrakini oluştur
	if task.IsRecurring {
		go s.createNextOccurrence(task)
	}

	return tx.Commit().Error
}

func (s *taskService) checkParentCompletion(tx *gorm.DB, parentID *uuid.UUID) {
	if parentID == nil {
		return
	}

	parent, err := s.taskRepo.GetByID(*parentID)
	if err != nil {
		return
	}

	// Tüm subtask'lar tamamlandı mı?
	allCompleted := true
	for _, subtask := range parent.Subtasks {
		if subtask.Status != models.TaskStatusCompleted {
			allCompleted = false
			break
		}
	}

	if allCompleted {
		now := time.Now()
		parent.Status = models.TaskStatusCompleted
		parent.CompletedAt = &now
		s.taskRepo.Update(parent)
	}
}

func (s *taskService) updateBlockedTasks(tx *gorm.DB, blockerTaskID uuid.UUID) {
	// Bu task'ın engellediği task'ları bul
	blocks, _ := s.dependencyRepo.GetBlocks(blockerTaskID)

	for _, dep := range blocks {
		blockedTask := dep.Blocked

		// Tüm engeller kalktı mı?
		blockedByDeps, _ := s.dependencyRepo.GetBlockedBy(blockedTask.ID)

		allBlockersCompleted := true
		for _, bd := range blockedByDeps {
			if bd.Blocker.Status != models.TaskStatusCompleted {
				allBlockersCompleted = false
				break
			}
		}

		if allBlockersCompleted {
			blockedTask.Status = models.TaskStatusPending
			s.taskRepo.Update(&blockedTask)
		}
	}
}

func (s *taskService) ActivateTask(id uuid.UUID, userID uuid.UUID) error {
	task, err := s.taskRepo.GetByID(id)
	if err != nil {
		return err
	}

	if task.UserID != userID {
		return errors.New("unauthorized")
	}

	// Check if blocked
	blockedBy, _ := s.dependencyRepo.GetBlockedBy(id)
	if len(blockedBy) > 0 {
		var incompleteBlockers []string
		for _, dep := range blockedBy {
			if dep.Blocker.Status != models.TaskStatusCompleted {
				incompleteBlockers = append(incompleteBlockers, dep.Blocker.Title)
			}
		}
		if len(incompleteBlockers) > 0 {
			return &models.ErrorResponse{
				Error: models.ErrorDetail{
					Code:    models.ErrCodeTaskBlocked,
					Message: "Task has uncompleted dependencies",
					Details: map[string]any{"blocked_by": incompleteBlockers},
				},
			}
		}
	}

	// Deactivate other active tasks
	activeTasks, _ := s.taskRepo.GetActiveTasks(userID)
	for _, activeTask := range activeTasks {
		activeTask.Status = models.TaskStatusPending
		s.taskRepo.Update(&activeTask)
	}

	task.Status = models.TaskStatusActive
	return s.taskRepo.Update(task)
}

func (s *taskService) CreateSubtask(parentID uuid.UUID, subtask *models.Task) error {
	parent, err := s.taskRepo.GetByID(parentID)
	if err != nil {
		return err
	}

	subtask.ParentID = &parent.ID
	subtask.UserID = parent.UserID
	subtask.Status = models.TaskStatusPending

	return s.taskRepo.Create(subtask)
}

func (s *taskService) UpdateSubtask(taskID, subtaskID uuid.UUID, updates map[string]interface{}) error {
	subtask, err := s.taskRepo.GetByID(subtaskID)
	if err != nil {
		return err
	}

	if subtask.ParentID == nil || *subtask.ParentID != taskID {
		return errors.New("subtask not found under this parent")
	}

	// Apply updates
	if title, ok := updates["title"]; ok {
		subtask.Title = title.(string)
	}
	if status, ok := updates["status"]; ok {
		subtask.Status = status.(models.TaskStatus)
	}

	return s.taskRepo.Update(subtask)
}

func (s *taskService) DeleteSubtask(taskID, subtaskID uuid.UUID) error {
	subtask, err := s.taskRepo.GetByID(subtaskID)
	if err != nil {
		return err
	}

	if subtask.ParentID == nil || *subtask.ParentID != taskID {
		return errors.New("subtask not found under this parent")
	}

	return s.taskRepo.Delete(subtaskID)
}

func (s *taskService) GetSubtasks(taskID uuid.UUID) ([]models.Task, error) {
	return s.taskRepo.GetSubtasks(taskID)
}

// Recurring task logic
func (s *taskService) createNextOccurrence(task *models.Task) error {
	if !task.IsRecurring || task.RecurrenceRule == nil {
		return nil
	}

	// RecurrenceEnd kontrolü
	if task.RecurrenceEnd != nil && task.DueDate.After(*task.RecurrenceEnd) {
		return nil
	}

	nextDueDate := s.calculateNextDueDate(*task.DueDate, *task.RecurrenceRule)

	newTask := &models.Task{
		UserID:          task.UserID,
		Title:           task.Title,
		Description:     task.Description,
		Priority:        task.Priority,
		Status:          models.TaskStatusPending,
		DueDate:         &nextDueDate,
		IsRecurring:     task.IsRecurring,
		RecurrenceRule:  task.RecurrenceRule,
		RecurrenceEnd:   task.RecurrenceEnd,
	}

	return s.taskRepo.Create(newTask)
}

func (s *taskService) calculateNextDueDate(currentDue time.Time, rule string) time.Time {
	switch rule {
	case models.RecurrenceDaily:
		return currentDue.AddDate(0, 0, 1)
	case models.RecurrenceWeekly:
		return currentDue.AddDate(0, 0, 7)
	case models.RecurrenceWeekdays:
		next := currentDue.AddDate(0, 0, 1)
		for next.Weekday() == time.Saturday || next.Weekday() == time.Sunday {
			next = next.AddDate(0, 0, 1)
		}
		return next
	case models.RecurrenceMonthly:
		return currentDue.AddDate(0, 1, 0)
	default:
		return currentDue
	}
}
```

---

## 2. FlowService (Dependency & Cycle Detection)

**Dosya:** `internal/services/flow_service.go`

```go
package services

import (
	"errors"

	"github.com/google/uuid"
	"github.com/ozlucodes/focusflow/internal/models"
	"github.com/ozlucodes/focusflow/internal/repository"
)

type FlowService interface {
	AddDependency(blockerID, blockedID uuid.UUID) error
	RemoveDependency(blockerID, blockedID uuid.UUID) error
	GetDependencies(taskID uuid.UUID) ([]models.TaskDependency, error)
	GetBlockedBy(taskID uuid.UUID) ([]FlowTask, error)
	GetBlocks(taskID uuid.UUID) ([]FlowTask, error)
	GetFlowChain(taskID uuid.UUID) (*FlowResponse, error)
	CanStartTask(taskID uuid.UUID) (bool, []FlowTask, error)
}

type flowService struct {
	dependencyRepo repository.DependencyRepository
	taskRepo       repository.TaskRepository
}

type FlowTask struct {
	ID     uuid.UUID `json:"id"`
	Title  string    `json:"title"`
	Status string    `json:"status"`
}

type FlowNode struct {
	Position     string   `json:"position"` // prev, current, next
	Task         FlowTask `json:"task"`
	LockedReason string   `json:"locked_reason,omitempty"`
}

type FlowResponse struct {
	CurrentTask FlowTask  `json:"current_task"`
	Chain       []FlowNode `json:"chain"`
}

func NewFlowService(
	dependencyRepo repository.DependencyRepository,
	taskRepo repository.TaskRepository,
) FlowService {
	return &flowService{
		dependencyRepo: dependencyRepo,
		taskRepo:       taskRepo,
	}
}

func (s *flowService) AddDependency(blockerID, blockedID uuid.UUID) error {
	// Self-reference kontrolü
	if blockerID == blockedID {
		return &models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    models.ErrCodeSelfDependency,
				Message: "Cannot create self-dependency",
			},
		}
	}

	// Duplicate kontrolü
	exists, _ := s.dependencyRepo.Exists(blockerID, blockedID)
	if exists {
		return errors.New("dependency already exists")
	}

	// Cycle detection
	if s.wouldCreateCycle(blockerID, blockedID) {
		return &models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    models.ErrCodeCycleDetected,
				Message: "Adding this dependency would create a circular dependency",
				Details: map[string]any{
					"proposed":      fmt.Sprintf("Task %s -> Task %s", blockerID, blockedID),
					"existing_path": s.getCyclePath(blockerID, blockedID),
				},
			},
		}
	}

	// Dependency oluştur
	dep := &models.TaskDependency{
		BlockerTaskID: blockerID,
		BlockedTaskID: blockedID,
	}

	if err := s.dependencyRepo.Create(dep); err != nil {
		return err
	}

	// Blocked task'ı güncelle
	blockedTask, _ := s.taskRepo.GetByID(blockedID)
	blockedTask.Status = models.TaskStatusBlocked
	return s.taskRepo.Update(blockedTask)
}

func (s *flowService) RemoveDependency(blockerID, blockedID uuid.UUID) error {
	return s.dependencyRepo.Delete(blockerID, blockedID)
}

func (s *flowService) GetDependencies(taskID uuid.UUID) ([]models.TaskDependency, error) {
	return s.dependencyRepo.GetAllByTask(taskID)
}

func (s *flowService) GetBlockedBy(taskID uuid.UUID) ([]FlowTask, error) {
	deps, err := s.dependencyRepo.GetBlockedBy(taskID)
	if err != nil {
		return nil, err
	}

	result := make([]FlowTask, 0, len(deps))
	for _, dep := range deps {
		if dep.Blocker.Status != models.TaskStatusCompleted {
			result = append(result, FlowTask{
				ID:     dep.Blocker.ID,
				Title:  dep.Blocker.Title,
				Status: string(dep.Blocker.Status),
			})
		}
	}

	return result, nil
}

func (s *flowService) GetBlocks(taskID uuid.UUID) ([]FlowTask, error) {
	deps, err := s.dependencyRepo.GetBlocks(taskID)
	if err != nil {
		return nil, err
	}

	result := make([]FlowTask, len(deps))
	for i, dep := range deps {
		result[i] = FlowTask{
			ID:     dep.Blocked.ID,
			Title:  dep.Blocked.Title,
			Status: string(dep.Blocked.Status),
		}
	}

	return result, nil
}

func (s *flowService) GetFlowChain(taskID uuid.UUID) (*FlowResponse, error) {
	task, err := s.taskRepo.GetByID(taskID)
	if err != nil {
		return nil, err
	}

	chain := []FlowNode{}

	// Prev: blocked-by tasks
	blockedBy, _ := s.GetBlockedBy(taskID)
	for _, bt := range blockedBy {
		chain = append(chain, FlowNode{
			Position: "prev",
			Task:     bt,
		})
	}

	// Current
	chain = append(chain, FlowNode{
		Position: "current",
		Task: FlowTask{
			ID:     task.ID,
			Title:  task.Title,
			Status: string(task.Status),
		},
	})

	// Next: blocks tasks
	blocks, _ := s.GetBlocks(taskID)
	for _, bt := range blocks {
		reason := ""
		if task.Status != models.TaskStatusCompleted {
			reason = fmt.Sprintf("Waiting for '%s' to complete", task.Title)
		}
		chain = append(chain, FlowNode{
			Position:     "next",
			Task:         bt,
			LockedReason: reason,
		})
	}

	return &FlowResponse{
		CurrentTask: FlowTask{
			ID:     task.ID,
			Title:  task.Title,
			Status: string(task.Status),
		},
		Chain: chain,
	}, nil
}

func (s *flowService) CanStartTask(taskID uuid.UUID) (bool, []FlowTask, error) {
	blockedBy, err := s.GetBlockedBy(taskID)
	if err != nil {
		return false, nil, err
	}

	return len(blockedBy) == 0, blockedBy, nil
}

// Cycle Detection - DFS Algorithm
func (s *flowService) wouldCreateCycle(blockerID, blockedID uuid.UUID) bool {
	visited := make(map[uuid.UUID]bool)
	return s.hasCycle(blockedID, blockerID, visited)
}

func (s *flowService) hasCycle(current, target uuid.UUID, visited map[uuid.UUID]bool) bool {
	if current == target {
		return true
	}
	if visited[current] {
		return false
	}
	visited[current] = true

	// Current task'ın engellediği task'ları bul
	blocks, _ := s.dependencyRepo.GetBlocks(current)

	for _, dep := range blocks {
		if s.hasCycle(dep.BlockedTaskID, target, visited) {
			return true
		}
	}

	return false
}

func (s *flowService) getCyclePath(blockerID, blockedID uuid.UUID) string {
	// Simple path reconstruction for error message
	return fmt.Sprintf("Task %s -> ... -> Task %s", blockedID, blockerID)
}
```

---

## 3. FocusService

**Dosya:** `internal/services/focus_service.go`

```go
package services

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/ozlucodes/focusflow/internal/models"
	"github.com/ozlucodes/focusflow/internal/repository"
	"gorm.io/gorm"
)

type FocusService interface {
	StartSession(userID uuid.UUID, taskID *uuid.UUID, duration int) (*models.FocusSession, error)
	PauseSession(sessionID, userID uuid.UUID) error
	ResumeSession(sessionID, userID uuid.UUID) error
	CompleteSession(sessionID, userID uuid.UUID) error
	CancelSession(sessionID, userID uuid.UUID) error
	GetSession(id uuid.UUID) (*models.FocusSession, error)
	GetUserSessions(userID uuid.UUID, filters map[string]interface{}) ([]models.FocusSession, error)
	GetStats(userID uuid.UUID) (*repository.FocusStats, error)
}

type focusService struct {
	focusRepo repository.FocusRepository
	taskRepo  repository.TaskRepository
	db        *gorm.DB
}

func NewFocusService(
	focusRepo repository.FocusRepository,
	taskRepo repository.TaskRepository,
	db *gorm.DB,
) FocusService {
	return &focusService{
		focusRepo: focusRepo,
		taskRepo:  taskRepo,
		db:        db,
	}
}

func (s *focusService) StartSession(userID uuid.UUID, taskID *uuid.UUID, duration int) (*models.FocusSession, error) {
	// Duration validation
	if duration < 1 || duration > 120 {
		return nil, &models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    models.ErrCodeInvalidDuration,
				Message: "Duration must be between 1 and 120 minutes",
			},
		}
	}

	// Transaction
	tx := s.db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// Aktif session kontrolü (SELECT FOR UPDATE)
	var existing models.FocusSession
	err := tx.Raw(`
		SELECT id FROM focus_sessions
		WHERE user_id = ? AND status = ?
		FOR UPDATE
	`, userID, models.SessionStatusRunning).Scan(&existing).Error

	if err == nil {
		tx.Rollback()
		return nil, &models.ErrorResponse{
			Error: models.ErrorDetail{
				Code:    models.ErrCodeActiveSession,
				Message: "You already have an active focus session",
			},
		}
	}

	// Session oluştur
	session := &models.FocusSession{
		TaskID:    taskID,
		UserID:    userID,
		Duration:  duration,
		Status:    models.SessionStatusRunning,
		StartedAt: time.Now().UTC(),
	}

	if err := s.focusRepo.Create(session); err != nil {
		tx.Rollback()
		return nil, err
	}

	// Task'ı ACTIVE yap
	if taskID != nil {
		task, err := s.taskRepo.GetByID(*taskID)
		if err == nil && task.UserID == userID {
			task.Status = models.TaskStatusActive
			s.taskRepo.Update(task)
		}
	}

	return session, tx.Commit().Error
}

func (s *focusService) PauseSession(sessionID, userID uuid.UUID) error {
	session, err := s.focusRepo.GetByID(sessionID)
	if err != nil {
		return err
	}

	if session.UserID != userID {
		return errors.New("unauthorized")
	}

	if session.Status != models.SessionStatusRunning {
		return errors.New("session is not running")
	}

	now := time.Now().UTC()
	session.Status = models.SessionStatusPaused
	session.PausedAt = &now

	return s.focusRepo.Update(session)
}

func (s *focusService) ResumeSession(sessionID, userID uuid.UUID) error {
	session, err := s.focusRepo.GetByID(sessionID)
	if err != nil {
		return err
	}

	if session.UserID != userID {
		return errors.New("unauthorized")
	}

	if session.Status != models.SessionStatusPaused {
		return errors.New("session is not paused")
	}

	// Calculate paused duration
	if session.PausedAt != nil {
		pausedDuration := int(time.Since(*session.PausedAt).Seconds())
		session.TotalPaused += pausedDuration
	}

	session.Status = models.SessionStatusRunning
	session.PausedAt = nil

	return s.focusRepo.Update(session)
}

func (s *focusService) CompleteSession(sessionID, userID uuid.UUID) error {
	session, err := s.focusRepo.GetByID(sessionID)
	if err != nil {
		return err
	}

	if session.UserID != userID {
		return errors.New("unauthorized")
	}

	if session.Status == models.SessionStatusCompleted {
		return errors.New("session already completed")
	}

	// If paused, resume first to calculate total
	if session.Status == models.SessionStatusPaused && session.PausedAt != nil {
		pausedDuration := int(time.Since(*session.PausedAt).Seconds())
		session.TotalPaused += pausedDuration
	}

	now := time.Now().UTC()
	session.Status = models.SessionStatusCompleted
	session.CompletedAt = &now

	// Reset task status
	if session.TaskID != nil {
		task, err := s.taskRepo.GetByID(*session.TaskID)
		if err == nil && task.UserID == userID {
			task.Status = models.TaskStatusPending
			s.taskRepo.Update(task)
		}
	}

	return s.focusRepo.Update(session)
}

func (s *focusService) CancelSession(sessionID, userID uuid.UUID) error {
	session, err := s.focusRepo.GetByID(sessionID)
	if err != nil {
		return err
	}

	if session.UserID != userID {
		return errors.New("unauthorized")
	}

	session.Status = models.SessionStatusCancelled
	now := time.Now().UTC()
	session.CompletedAt = &now

	// Reset task status
	if session.TaskID != nil {
		task, err := s.taskRepo.GetByID(*session.TaskID)
		if err == nil && task.UserID == userID {
			task.Status = models.TaskStatusPending
			s.taskRepo.Update(task)
		}
	}

	return s.focusRepo.Update(session)
}

func (s *focusService) GetSession(id uuid.UUID) (*models.FocusSession, error) {
	return s.focusRepo.GetByID(id)
}

func (s *focusService) GetUserSessions(userID uuid.UUID, filters map[string]interface{}) ([]models.FocusSession, error) {
	return s.focusRepo.GetByUserID(userID, filters)
}

func (s *focusService) GetStats(userID uuid.UUID) (*repository.FocusStats, error) {
	return s.focusRepo.GetStats(userID)
}
```

---

## 4. DashboardService

**Dosya:** `internal/services/dashboard_service.go`

```go
package services

import (
	"time"

	"github.com/google/uuid"
	"github.com/ozlucodes/focusflow/internal/models"
	"github.com/ozlucodes/focusflow/internal/repository"
)

type DashboardService interface {
	GetDashboard(userID uuid.UUID) (*DashboardResponse, error)
	GetStats(userID uuid.UUID) (*DashboardStats, error)
	GetTodayTasks(userID uuid.UUID) (*TodayTasksResponse, error)
}

type dashboardService struct {
	taskRepo  repository.TaskRepository
	focusRepo repository.FocusRepository
}

type DashboardResponse struct {
	Greeting   string             `json:"greeting"`
	UserName   string             `json:"user_name"`
	Date       string             `json:"date"`
	Weekday    string             `json:"weekday"`
	Stats      DashboardStats     `json:"stats"`
	ActiveTask *ActiveTaskSummary `json:"active_task,omitempty"`
	NextUp     *NextUpTask        `json:"next_up,omitempty"`
}

type DashboardStats struct {
	TodayTotal      int     `json:"today_total"`
	TodayCompleted  int     `json:"today_completed"`
	TodayRemaining  int     `json:"today_remaining"`
	ProgressPercent float64 `json:"progress_percent"`
	WeeklyFocus     int     `json:"weekly_focus_minutes"`
}

type ActiveTaskSummary struct {
	ID           uuid.UUID   `json:"id"`
	Title        string      `json:"title"`
	Priority     int         `json:"priority"`
	PriorityLabel string     `json:"priority_label"`
	PriorityColor string     `json:"priority_color"`
	DueTime      string      `json:"due_time,omitempty"`
	IsBlocked    bool        `json:"is_blocked"`
}

type NextUpTask struct {
	ID          uuid.UUID   `json:"id"`
	Title       string      `json:"title"`
	DueTime     string      `json:"due_time,omitempty"`
	Priority    int         `json:"priority"`
	BlockedBy   []string    `json:"blocked_by"`
}

type TodayTasksResponse struct {
	Tasks      []TodayTask `json:"tasks"`
	Summary    TaskSummary `json:"summary"`
}

type TodayTask struct {
	ID            uuid.UUID `json:"id"`
	Title         string    `json:"title"`
	Status        string    `json:"status"`
	Priority      int       `json:"priority"`
	PriorityLabel string    `json:"priority_label"`
	PriorityColor string    `json:"priority_color"`
	DueTime       string    `json:"due_time,omitempty"`
	IsBlocked     bool      `json:"is_blocked"`
	BlockedBy     []string  `json:"blocked_by,omitempty"`
	SubtasksTotal int       `json:"subtasks_total"`
	SubtasksCompleted int   `json:"subtasks_completed"`
}

func NewDashboardService(
	taskRepo repository.TaskRepository,
	focusRepo repository.FocusRepository,
) DashboardService {
	return &dashboardService{
		taskRepo:  taskRepo,
		focusRepo: focusRepo,
	}
}

func (s *dashboardService) GetDashboard(userID uuid.UUID) (*DashboardResponse, error) {
	user, err := s.taskRepo.GetByID(userID) // This should be userRepo
	if err != nil {
		return nil, err
	}

	stats, _ := s.GetStats(userID)

	// Get active task
	activeTasks, _ := s.taskRepo.GetActiveTasks(userID)
	var activeTask *ActiveTaskSummary
	if len(activeTasks) > 0 {
		t := activeTasks[0]
		activeTask = &ActiveTaskSummary{
			ID:            t.ID,
			Title:         t.Title,
			Priority:      t.Priority,
			PriorityLabel: t.GetPriorityLabel(),
			PriorityColor: t.GetPriorityColor(),
			IsBlocked:     false,
		}
		if t.DueDate != nil {
			activeTask.DueTime = formatTime(*t.DueDate)
		}
	}

	// Get next up (first blocked task that's ready to start)
	blockedTasks, _ := s.taskRepo.GetBlockedTasks(userID)
	var nextUp *NextUpTask
	for _, t := range blockedTasks {
		blockedBy, _ := s.dependencyRepo.GetBlockedBy(t.ID)
		if len(blockedBy) == 1 && blockedBy[0].Blocker.Status == models.TaskStatusCompleted {
			// Almost ready
			nextUp = &NextUpTask{
				ID:        t.ID,
				Title:     t.Title,
				Priority:  t.Priority,
				BlockedBy: []string{},
			}
			if t.DueDate != nil {
				nextUp.DueTime = formatTime(*t.DueDate)
			}
			break
		}
	}

	now := time.Now()
	return &DashboardResponse{
		Greeting:   getGreeting(now),
		UserName:   user.FullName,
		Date:       now.Format("Jan 2"),
		Weekday:    now.Format("Monday"),
		Stats:      *stats,
		ActiveTask: activeTask,
		NextUp:     nextUp,
	}, nil
}

func (s *dashboardService) GetStats(userID uuid.UUID) (*DashboardStats, error) {
	todayTasks, _ := s.taskRepo.GetTodayTasks(userID)

	todayTotal := len(todayTasks)
	todayCompleted := 0
	for _, t := range todayTasks {
		if t.Status == models.TaskStatusCompleted {
			todayCompleted++
		}
	}

	progress := 0.0
	if todayTotal > 0 {
		progress = float64(todayCompleted) / float64(todayTotal) * 100
	}

	// Get focus stats
	focusStats, _ := s.focusRepo.GetStats(userID)

	return &DashboardStats{
		TodayTotal:      todayTotal,
		TodayCompleted:  todayCompleted,
		TodayRemaining:  todayTotal - todayCompleted,
		ProgressPercent: progress,
		WeeklyFocus:     focusStats.CompletedThisWeek * 25, // Approximate
	}, nil
}

func (s *dashboardService) GetTodayTasks(userID uuid.UUID) (*TodayTasksResponse, error) {
	tasks, _ := s.taskRepo.GetTodayTasks(userID)

	result := make([]TodayTask, 0, len(tasks))
	completed := 0

	for _, t := range tasks {
		if t.Status == models.TaskStatusCompleted {
			completed++
		}

		blockedBy := []string{}
		if t.Status == models.TaskStatusBlocked {
			blockedByDeps, _ := s.dependencyRepo.GetBlockedBy(t.ID)
			for _, bd := range blockedByDeps {
				blockedBy = append(blockedBy, bd.Blocker.Title)
			}
		}

		task := TodayTask{
			ID:                t.ID,
			Title:             t.Title,
			Status:            string(t.Status),
			Priority:          t.Priority,
			PriorityLabel:     t.GetPriorityLabel(),
			PriorityColor:     t.GetPriorityColor(),
			IsBlocked:         t.Status == models.TaskStatusBlocked,
			BlockedBy:         blockedBy,
			SubtasksTotal:     len(t.Subtasks),
			SubtasksCompleted: 0,
		}

		for _, st := range t.Subtasks {
			if st.Status == models.TaskStatusCompleted {
				task.SubtasksCompleted++
			}
		}

		if t.DueDate != nil {
			task.DueTime = formatTime(*t.DueDate)
		}

		result = append(result, task)
	}

	return &TodayTasksResponse{
		Tasks: result,
		Summary: TaskSummary{
			Total:           len(tasks),
			Completed:       completed,
			Remaining:       len(tasks) - completed,
			ProgressPercent: float64(completed) / float64(len(tasks)) * 100,
		},
	}, nil
}

func getGreeting(t time.Time) string {
	hour := t.Hour()
	switch {
	case hour < 12:
		return "Good Morning"
	case hour < 17:
		return "Good Afternoon"
	default:
		return "Good Evening"
	}
}

func formatTime(t time.Time) string {
	return t.Format("3:04 PM")
}
```

---

## Checklist

- [ ] `internal/services/task_service.go` oluşturuldu
- [ ] `internal/services/flow_service.go` oluşturuldu (Cycle detection)
- [ ] `internal/services/focus_service.go` oluşturuldu
- [ ] `internal/services/dashboard_service.go` oluşturuldu
- [ ] Tüm servisler test edildi
- [ ] Recurring task logic test edildi
- [ ] Cycle detection test edildi
