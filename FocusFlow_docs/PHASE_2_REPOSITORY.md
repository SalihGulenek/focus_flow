# Phase 2: Repository Layer

## Amaç
Veritabanı işlemlerini soyutlamak için repository pattern'i implement etmek.

---

## Repository Interface'leri

**Dosya:** `internal/repository/repository.go`

```go
package repository

import (
	"github.com/google/uuid"
	"github.com/ozlucodes/focusflow/internal/models"
	"gorm.io/gorm"
)

type UserRepository interface {
	Create(user *models.User) error
	GetByID(id uuid.UUID) (*models.User, error)
	GetByEmail(email string) (*models.User, error)
	Update(user *models.User) error
	Delete(id uuid.UUID) error
}

type TaskRepository interface {
	Create(task *models.Task) error
	GetByID(id uuid.UUID) (*models.Task, error)
	GetByUserID(userID uuid.UUID, offset, limit int, filters map[string]interface{}) ([]models.Task, int64, error)
	Update(task *models.Task) error
	Delete(id uuid.UUID) error
	GetSubtasks(parentID uuid.UUID) ([]models.Task, error)
	GetActiveTasks(userID uuid.UUID) ([]models.Task, error)
	GetBlockedTasks(userID uuid.UUID) ([]models.Task, error)
	GetTodayTasks(userID uuid.UUID) ([]models.Task, error)
}

type DependencyRepository interface {
	Create(dep *models.TaskDependency) error
	Delete(blockerID, blockedID uuid.UUID) error
	GetBlockedBy(taskID uuid.UUID) ([]models.TaskDependency, error)
	GetBlocks(taskID uuid.UUID) ([]models.TaskDependency, error)
	GetAllByTask(taskID uuid.UUID) ([]models.TaskDependency, error)
	Exists(blockerID, blockedID uuid.UUID) (bool, error)
}

type ReminderRepository interface {
	Create(reminder *models.Reminder) error
	GetByID(id uuid.UUID) (*models.Reminder, error)
	GetByTaskID(taskID uuid.UUID) ([]models.Reminder, error)
	GetPendingReminders() ([]models.Reminder, error)
	Update(reminder *models.Reminder) error
	Delete(id uuid.UUID) error
	MarkAsSent(id uuid.UUID) error
}

type TagRepository interface {
	Create(tag *models.Tag) error
	GetByID(id uuid.UUID) (*models.Tag, error)
	GetByUserID(userID uuid.UUID) ([]models.Tag, error)
	Update(tag *models.Tag) error
	Delete(id uuid.UUID) error
	AssignToTask(taskID, tagID uuid.UUID) error
	RemoveFromTask(taskID, tagID uuid.UUID) error
	GetTaskTags(taskID uuid.UUID) ([]models.Tag, error)
}

type FocusRepository interface {
	Create(session *models.FocusSession) error
	GetByID(id uuid.UUID) (*models.FocusSession, error)
	GetActiveSession(userID uuid.UUID) (*models.FocusSession, error)
	GetByUserID(userID uuid.UUID, filters map[string]interface{}) ([]models.FocusSession, error)
	Update(session *models.FocusSession) error
	GetStats(userID uuid.UUID) (*FocusStats, error)
}

type FocusStats struct {
	TotalSessions    int
	TotalMinutes     int
	CompletedToday   int
	MinutesToday     int
	LongestStreak    int
	CompletedThisWeek int
}
```

---

## 1. UserRepository Implementation

**Dosya:** `internal/repository/user_repo.go`

```go
package repository

import (
	"errors"

	"github.com/google/uuid"
	"github.com/ozlucodes/focusflow/internal/models"
	"gorm.io/gorm"
)

type userRepository struct {
	db *gorm.DB
}

func NewUserRepository(db *gorm.DB) UserRepository {
	return &userRepository{db: db}
}

func (r *userRepository) Create(user *models.User) error {
	return r.db.Create(user).Error
}

func (r *userRepository) GetByID(id uuid.UUID) (*models.User, error) {
	var user models.User
	err := r.db.Where("id = ?", id).First(&user).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("user not found")
		}
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) GetByEmail(email string) (*models.User, error) {
	var user models.User
	err := r.db.Where("email = ?", email).First(&user).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("user not found")
		}
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) Update(user *models.User) error {
	return r.db.Save(user).Error
}

func (r *userRepository) Delete(id uuid.UUID) error {
	return r.db.Delete(&models.User{}, "id = ?", id).Error
}
```

---

## 2. TaskRepository Implementation

**Dosya:** `internal/repository/task_repo.go`

```go
package repository

import (
	"errors"

	"github.com/google/uuid"
	"github.com/ozlucodes/focusflow/internal/models"
	"gorm.io/gorm"
)

type taskRepository struct {
	db *gorm.DB
}

func NewTaskRepository(db *gorm.DB) TaskRepository {
	return &taskRepository{db: db}
}

func (r *taskRepository) Create(task *models.Task) error {
	return r.db.Create(task).Error
}

func (r *taskRepository) GetByID(id uuid.UUID) (*models.Task, error) {
	var task models.Task
	err := r.db.
		Preload("Subtasks").
		Preload("Tags").
		Preload("Reminders").
		Preload("Dependencies").
		Preload("BlockedBy").
		Where("id = ?", id).
		First(&task).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("task not found")
		}
		return nil, err
	}
	return &task, nil
}

func (r *taskRepository) GetByUserID(userID uuid.UUID, offset, limit int, filters map[string]interface{}) ([]models.Task, int64, error) {
	var tasks []models.Task
	var total int64

	query := r.db.Model(&models.Task{}).Where("user_id = ? AND parent_id IS NULL", userID)

	// Apply filters
	if status, ok := filters["status"]; ok {
		query = query.Where("status = ?", status)
	}
	if priority, ok := filters["priority"]; ok {
		query = query.Where("priority = ?", priority)
	}
	if isRecurring, ok := filters["is_recurring"]; ok {
		query = query.Where("is_recurring = ?", isRecurring)
	}

	// Count total
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// Fetch with pagination
	err := query.
		Preload("Tags").
		Preload("Subtasks").
		Order("priority ASC, created_at DESC").
		Limit(limit).
		Offset(offset).
		Find(&tasks).Error

	return tasks, total, err
}

func (r *taskRepository) Update(task *models.Task) error {
	return r.db.Save(task).Error
}

func (r *taskRepository) Delete(id uuid.UUID) error {
	return r.db.Delete(&models.Task{}, "id = ?", id).Error
}

func (r *taskRepository) GetSubtasks(parentID uuid.UUID) ([]models.Task, error) {
	var subtasks []models.Task
	err := r.db.Where("parent_id = ?", parentID).Find(&subtasks).Error
	return subtasks, err
}

func (r *taskRepository) GetActiveTasks(userID uuid.UUID) ([]models.Task, error) {
	var tasks []models.Task
	err := r.db.
		Where("user_id = ? AND status = ?", userID, models.TaskStatusActive).
		Preload("Tags").
		Find(&tasks).Error
	return tasks, err
}

func (r *taskRepository) GetBlockedTasks(userID uuid.UUID) ([]models.Task, error) {
	var tasks []models.Task
	err := r.db.
		Where("user_id = ? AND status = ?", userID, models.TaskStatusBlocked).
		Preload("Tags").
		Preload("BlockedBy").
		Find(&tasks).Error
	return tasks, err
}

func (r *taskRepository) GetTodayTasks(userID uuid.UUID) ([]models.Task, error) {
	var tasks []models.Task
	// Bugünün başı ve sonu
	today := time.Now().Truncate(24 * time.Hour)
	tomorrow := today.Add(24 * time.Hour)

	err := r.db.
		Where("user_id = ? AND parent_id IS NULL", userID).
		Where("(due_date >= ? AND due_date < ?) OR created_at >= ?", today, tomorrow, today).
		Where("status != ?", models.TaskStatusCompleted).
		Preload("Tags").
		Preload("BlockedBy").
		Order("priority ASC, due_date ASC").
		Find(&tasks).Error

	return tasks, err
}
```

---

## 3. DependencyRepository Implementation

**Dosya:** `internal/repository/dependency_repo.go`

```go
package repository

import (
	"errors"

	"github.com/google/uuid"
	"github.com/ozlucodes/focusflow/internal/models"
	"gorm.io/gorm"
)

type dependencyRepository struct {
	db *gorm.DB
}

func NewDependencyRepository(db *gorm.DB) DependencyRepository {
	return &dependencyRepository{db: db}
}

func (r *dependencyRepository) Create(dep *models.TaskDependency) error {
	return r.db.Create(dep).Error
}

func (r *dependencyRepository) Delete(blockerID, blockedID uuid.UUID) error {
	return r.db.
		Where("blocker_task_id = ? AND blocked_task_id = ?", blockerID, blockedID).
		Delete(&models.TaskDependency{}).Error
}

func (r *dependencyRepository) GetBlockedBy(taskID uuid.UUID) ([]models.TaskDependency, error) {
	var deps []models.TaskDependency
	err := r.db.
		Preload("Blocker").
		Where("blocked_task_id = ?", taskID).
		Find(&deps).Error
	return deps, err
}

func (r *dependencyRepository) GetBlocks(taskID uuid.UUID) ([]models.TaskDependency, error) {
	var deps []models.TaskDependency
	err := r.db.
		Preload("Blocked").
		Where("blocker_task_id = ?", taskID).
		Find(&deps).Error
	return deps, err
}

func (r *dependencyRepository) GetAllByTask(taskID uuid.UUID) ([]models.TaskDependency, error) {
	var deps []models.TaskDependency
	err := r.db.
		Preload("Blocker").
		Preload("Blocked").
		Where("blocker_task_id = ? OR blocked_task_id = ?", taskID, taskID).
		Find(&deps).Error
	return deps, err
}

func (r *dependencyRepository) Exists(blockerID, blockedID uuid.UUID) (bool, error) {
	var count int64
	err := r.db.
		Model(&models.TaskDependency{}).
		Where("blocker_task_id = ? AND blocked_task_id = ?", blockerID, blockedID).
		Count(&count).Error
	return count > 0, err
}
```

---

## 4. ReminderRepository Implementation

**Dosya:** `internal/repository/reminder_repo.go`

```go
package repository

import (
	"errors"

	"github.com/google/uuid"
	"github.com/ozlucodes/focusflow/internal/models"
	"gorm.io/gorm"
)

type reminderRepository struct {
	db *gorm.DB
}

func NewReminderRepository(db *gorm.DB) ReminderRepository {
	return &reminderRepository{db: db}
}

func (r *reminderRepository) Create(reminder *models.Reminder) error {
	return r.db.Create(reminder).Error
}

func (r *reminderRepository) GetByID(id uuid.UUID) (*models.Reminder, error) {
	var reminder models.Reminder
	err := r.db.Preload("Task").Where("id = ?", id).First(&reminder).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("reminder not found")
		}
		return nil, err
	}
	return &reminder, nil
}

func (r *reminderRepository) GetByTaskID(taskID uuid.UUID) ([]models.Reminder, error) {
	var reminders []models.Reminder
	err := r.db.Where("task_id = ?", taskID).Order("remind_at ASC").Find(&reminders).Error
	return reminders, err
}

func (r *reminderRepository) GetPendingReminders() ([]models.Reminder, error) {
	var reminders []models.Reminder
	now := time.Now()
	err := r.db.
		Where("remind_at <= ? AND is_sent = ?", now, false).
		Preload("Task").
		Preload("Task.User").
		Find(&reminders).Error
	return reminders, err
}

func (r *reminderRepository) Update(reminder *models.Reminder) error {
	return r.db.Save(reminder).Error
}

func (r *reminderRepository) Delete(id uuid.UUID) error {
	return r.db.Delete(&models.Reminder{}, "id = ?", id).Error
}

func (r *reminderRepository) MarkAsSent(id uuid.UUID) error {
	now := time.Now()
	return r.db.Model(&models.Reminder{}).
		Where("id = ?", id).
		Updates(map[string]interface{}{
			"is_sent": true,
			"sent_at": &now,
		}).Error
}
```

---

## 5. TagRepository Implementation

**Dosya:** `internal/repository/tag_repo.go`

```go
package repository

import (
	"errors"

	"github.com/google/uuid"
	"github.com/ozlucodes/focusflow/internal/models"
	"gorm.io/gorm"
)

type tagRepository struct {
	db *gorm.DB
}

func NewTagRepository(db *gorm.DB) TagRepository {
	return &tagRepository{db: db}
}

func (r *tagRepository) Create(tag *models.Tag) error {
	return r.db.Create(tag).Error
}

func (r *tagRepository) GetByID(id uuid.UUID) (*models.Tag, error) {
	var tag models.Tag
	err := r.db.Preload("Tasks").Where("id = ?", id).First(&tag).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("tag not found")
		}
		return nil, err
	}
	return &tag, nil
}

func (r *tagRepository) GetByUserID(userID uuid.UUID) ([]models.Tag, error) {
	var tags []models.Tag
	err := r.db.Where("user_id = ?", userID).Preload("Tasks").Find(&tags).Error
	return tags, err
}

func (r *tagRepository) Update(tag *models.Tag) error {
	return r.db.Save(tag).Error
}

func (r *tagRepository) Delete(id uuid.UUID) error {
	return r.db.Select("Tasks").Delete(&models.Tag{}, "id = ?", id).Error
}

func (r *tagRepository) AssignToTask(taskID, tagID uuid.UUID) error {
	// GORM many-to-many relation
	return r.db.Exec(
		"INSERT INTO task_tags (task_id, tag_id) VALUES (?, ?) ON CONFLICT DO NOTHING",
		taskID, tagID,
	).Error
}

func (r *tagRepository) RemoveFromTask(taskID, tagID uuid.UUID) error {
	return r.db.Exec(
		"DELETE FROM task_tags WHERE task_id = ? AND tag_id = ?",
		taskID, tagID,
	).Error
}

func (r *tagRepository) GetTaskTags(taskID uuid.UUID) ([]models.Tag, error) {
	var tags []models.Tag
	err := r.db.
		Joins("JOIN task_tags ON task_tags.tag_id = tags.id").
		Where("task_tags.task_id = ?", taskID).
		Find(&tags).Error
	return tags, err
}
```

---

## 6. FocusRepository Implementation

**Dosya:** `internal/repository/focus_repo.go`

```go
package repository

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/ozlucodes/focusflow/internal/models"
	"gorm.io/gorm"
)

type focusRepository struct {
	db *gorm.DB
}

func NewFocusRepository(db *gorm.DB) FocusRepository {
	return &focusRepository{db: db}
}

func (r *focusRepository) Create(session *models.FocusSession) error {
	return r.db.Create(session).Error
}

func (r *focusRepository) GetByID(id uuid.UUID) (*models.FocusSession, error) {
	var session models.FocusSession
	err := r.db.Preload("Task").Where("id = ?", id).First(&session).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("session not found")
		}
		return nil, err
	}
	return &session, nil
}

func (r *focusRepository) GetActiveSession(userID uuid.UUID) (*models.FocusSession, error) {
	var session models.FocusSession
	err := r.db.
		Preload("Task").
		Where("user_id = ? AND status = ?", userID, models.SessionStatusRunning).
		First(&session).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil // No active session
		}
		return nil, err
	}
	return &session, nil
}

func (r *focusRepository) GetByUserID(userID uuid.UUID, filters map[string]interface{}) ([]models.FocusSession, error) {
	var sessions []models.FocusSession

	query := r.db.Model(&models.FocusSession{}).Where("user_id = ?", userID)

	if status, ok := filters["status"]; ok {
		query = query.Where("status = ?", status)
	}
	if taskID, ok := filters["task_id"]; ok {
		query = query.Where("task_id = ?", taskID)
	}

	err := query.
		Preload("Task").
		Order("started_at DESC").
		Find(&sessions).Error

	return sessions, err
}

func (r *focusRepository) Update(session *models.FocusSession) error {
	return r.db.Save(session).Error
}

func (r *focusRepository) GetStats(userID uuid.UUID) (*FocusStats, error) {
	stats := &FocusStats{}

	// Total sessions
	r.db.Model(&models.FocusSession{}).
		Where("user_id = ? AND status = ?", userID, models.SessionStatusCompleted).
		Count(&stats.TotalSessions)

	// Total minutes
	var totalMinutes int
	r.db.Model(&models.FocusSession{}).
		Select("COALESCE(SUM(duration - total_paused/60), 0)").
		Where("user_id = ? AND status = ?", userID, models.SessionStatusCompleted).
		Scan(&totalMinutes)
	stats.TotalMinutes = totalMinutes

	// Today's stats
	today := time.Now().Truncate(24 * time.Hour)
	tomorrow := today.Add(24 * time.Hour)

	r.db.Model(&models.FocusSession{}).
		Where("user_id = ? AND status = ? AND started_at >= ? AND started_at < ?",
			userID, models.SessionStatusCompleted, today, tomorrow).
		Count(&stats.CompletedToday)

	var minutesToday int
	r.db.Model(&models.FocusSession{}).
		Select("COALESCE(SUM(duration - total_paused/60), 0)").
		Where("user_id = ? AND status = ? AND started_at >= ? AND started_at < ?",
			userID, models.SessionStatusCompleted, today, tomorrow).
		Scan(&minutesToday)
	stats.MinutesToday = minutesToday

	// This week stats
	weekAgo := time.Now().AddDate(0, 0, -7)
	r.db.Model(&models.FocusSession{}).
		Where("user_id = ? AND status = ? AND started_at >= ?",
			userID, models.SessionStatusCompleted, weekAgo).
		Count(&stats.CompletedThisWeek)

	return stats, nil
}
```

---

## Checklist

- [ ] `internal/repository/repository.go` oluşturuldu (interface'ler)
- [ ] `internal/repository/user_repo.go` oluşturuldu
- [ ] `internal/repository/task_repo.go` oluşturuldu
- [ ] `internal/repository/dependency_repo.go` oluşturuldu
- [ ] `internal/repository/reminder_repo.go` oluşturuldu
- [ ] `internal/repository/tag_repo.go` oluşturuldu
- [ ] `internal/repository/focus_repo.go` oluşturuldu
- [ ] Tüm repository'ler test edildi
