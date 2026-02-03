# Phase 4: API Handlers & Routes

## Amaç
HTTP request'lerini yöneten handler ve route tanımlamalarını oluşturmak.

---

## 1. Task Handlers

**Dosya:** `internal/handlers/task_handler.go`

```go
package handlers

import (
	"strconv"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/ozlucodes/focusflow/internal/models"
	"github.com/ozlucodes/focusflow/internal/services"
)

type TaskHandler struct {
	taskService services.TaskService
}

func NewTaskHandler(taskService services.TaskService) *TaskHandler {
	return &TaskHandler{taskService: taskService}
}

// CreateTask creates a new task
// @Summary Create task
// @Tags tasks
// @Accept json
// @Produce json
// @Param task body models.Task true "Task object"
// @Success 200 {object} models.Task
// @Failure 400 {object} models.ErrorResponse
// @Router /api/tasks [post]
func (h *TaskHandler) CreateTask(c *fiber.Ctx) error {
	var task models.Task
	if err := c.BodyParser(&task); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid request body",
		))
	}

	// Get user ID from context (set by auth middleware)
	userID := c.Locals("userID").(uuid.UUID)
	task.UserID = userID

	if err := h.taskService.CreateTask(&task); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			err.Error(),
		))
	}

	return c.Status(201).JSON(task)
}

// GetTasks returns paginated task list
// @Summary Get tasks
// @Tags tasks
// @Produce json
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(20)
// @Param status query string false "Filter by status"
// @Param priority query int false "Filter by priority"
// @Success 200 {object} services.TaskListResponse
// @Router /api/tasks [get]
func (h *TaskHandler) GetTasks(c *fiber.Ctx) error {
	userID := c.Locals("userID").(uuid.UUID)

	// Pagination params
	page, _ := strconv.Atoi(c.Query("page", "1"))
	limit, _ := strconv.Atoi(c.Query("limit", "20"))

	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}

	// Filters
	filters := make(map[string]interface{})
	if status := c.Query("status"); status != "" {
		filters["status"] = status
	}
	if priority := c.QueryInt("priority"); priority > 0 {
		filters["priority"] = priority
	}

	response, err := h.taskService.GetTasks(userID, page, limit, filters)
	if err != nil {
		return c.Status(500).JSON(models.NewErrorResponse(
			"INTERNAL_ERROR",
			err.Error(),
		))
	}

	return c.JSON(response)
}

// GetTaskByID returns a single task
// @Summary Get task by ID
// @Tags tasks
// @Produce json
// @Param id path string true "Task ID"
// @Success 200 {object} models.Task
// @Failure 404 {object} models.ErrorResponse
// @Router /api/tasks/{id} [get]
func (h *TaskHandler) GetTaskByID(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid task ID",
		))
	}

	task, err := h.taskService.GetTaskByID(id)
	if err != nil {
		return c.Status(404).JSON(models.NewErrorResponse(
			models.ErrCodeNotFound,
			"Task not found",
		))
	}

	return c.JSON(task)
}

// UpdateTask updates a task
// @Summary Update task
// @Tags tasks
// @Accept json
// @Produce json
// @Param id path string true "Task ID"
// @Param task body models.Task true "Task object"
// @Success 200 {object} models.Task
// @Failure 400 {object} models.ErrorResponse
// @Router /api/tasks/{id} [put]
func (h *TaskHandler) UpdateTask(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid task ID",
		))
	}

	var task models.Task
	if err := c.BodyParser(&task); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid request body",
		))
	}

	task.ID = id
	if err := h.taskService.UpdateTask(&task); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			err.Error(),
		))
	}

	return c.JSON(task)
}

// DeleteTask deletes a task
// @Summary Delete task
// @Tags tasks
// @Produce json
// @Param id path string true "Task ID"
// @Success 204
// @Failure 400 {object} models.ErrorResponse
// @Router /api/tasks/{id} [delete]
func (h *TaskHandler) DeleteTask(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid task ID",
		))
	}

	userID := c.Locals("userID").(uuid.UUID)
	if err := h.taskService.DeleteTask(id, userID); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			err.Error(),
		))
	}

	return c.SendStatus(204)
}

// CompleteTask marks a task as completed
// @Summary Complete task
// @Tags tasks
// @Produce json
// @Param id path string true "Task ID"
// @Success 200 {object} models.Task
// @Failure 400 {object} models.ErrorResponse
// @Router /api/tasks/{id}/complete [post]
func (h *TaskHandler) CompleteTask(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid task ID",
		))
	}

	userID := c.Locals("userID").(uuid.UUID)
	if err := h.taskService.CompleteTask(id, userID); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			err.Error(),
		))
	}

	task, _ := h.taskService.GetTaskByID(id)
	return c.JSON(task)
}

// ActivateTask activates a task (sets to ACTIVE status)
// @Summary Activate task
// @Tags tasks
// @Produce json
// @Param id path string true "Task ID"
// @Success 200 {object} models.Task
// @Failure 400 {object} models.ErrorResponse
// @Router /api/tasks/{id}/activate [post]
func (h *TaskHandler) ActivateTask(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid task ID",
		))
	}

	userID := c.Locals("userID").(uuid.UUID)
	if err := h.taskService.ActivateTask(id, userID); err != nil {
		if errResp, ok := err.(*models.ErrorResponse); ok {
			return c.Status(400).JSON(errResp)
		}
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			err.Error(),
		))
	}

	task, _ := h.taskService.GetTaskByID(id)
	return c.JSON(task)
}

// CreateSubtask creates a subtask
// @Summary Create subtask
// @Tags tasks
// @Accept json
// @Produce json
// @Param id path string true "Parent task ID"
// @Param subtask body models.Task true "Subtask object"
// @Success 201 {object} models.Task
// @Router /api/tasks/{id}/subtasks [post]
func (h *TaskHandler) CreateSubtask(c *fiber.Ctx) error {
	parentID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid parent task ID",
		))
	}

	var subtask models.Task
	if err := c.BodyParser(&subtask); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid request body",
		))
	}

	if err := h.taskService.CreateSubtask(parentID, &subtask); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			err.Error(),
		))
	}

	return c.Status(201).JSON(subtask)
}

// GetSubtasks returns all subtasks for a task
// @Summary Get subtasks
// @Tags tasks
// @Produce json
// @Param id path string true "Parent task ID"
// @Success 200 {array} models.Task
// @Router /api/tasks/{id}/subtasks [get]
func (h *TaskHandler) GetSubtasks(c *fiber.Ctx) error {
	parentID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid parent task ID",
		))
	}

	subtasks, err := h.taskService.GetSubtasks(parentID)
	if err != nil {
		return c.Status(500).JSON(models.NewErrorResponse(
			"INTERNAL_ERROR",
			err.Error(),
		))
	}

	return c.JSON(subtasks)
}

// UpdateSubtask updates a subtask
// @Summary Update subtask
// @Tags tasks
// @Accept json
// @Produce json
// @Param id path string true "Parent task ID"
// @Param sub_id path string true "Subtask ID"
// @Param updates body map true "Updates"
// @Success 200 {object} models.Task
// @Router /api/tasks/{id}/subtasks/{sub_id} [put]
func (h *TaskHandler) UpdateSubtask(c *fiber.Ctx) error {
	taskID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid task ID",
		))
	}

	subtaskID, err := uuid.Parse(c.Params("sub_id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid subtask ID",
		))
	}

	var updates map[string]interface{}
	if err := c.BodyParser(&updates); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid request body",
		))
	}

	if err := h.taskService.UpdateSubtask(taskID, subtaskID, updates); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			err.Error(),
		))
	}

	subtask, _ := h.taskService.GetTaskByID(subtaskID)
	return c.JSON(subtask)
}

// DeleteSubtask deletes a subtask
// @Summary Delete subtask
// @Tags tasks
// @Produce json
// @Param id path string true "Parent task ID"
// @Param sub_id path string true "Subtask ID"
// @Success 204
// @Router /api/tasks/{id}/subtasks/{sub_id} [delete]
func (h *TaskHandler) DeleteSubtask(c *fiber.Ctx) error {
	taskID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid task ID",
		))
	}

	subtaskID, err := uuid.Parse(c.Params("sub_id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid subtask ID",
		))
	}

	if err := h.taskService.DeleteSubtask(taskID, subtaskID); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			err.Error(),
		))
	}

	return c.SendStatus(204)
}

// CompleteSubtask marks a subtask as completed
// @Summary Complete subtask
// @Tags tasks
// @Produce json
// @Param id path string true "Parent task ID"
// @Param sub_id path string true "Subtask ID"
// @Success 200 {object} models.Task
// @Router /api/tasks/{id}/subtasks/{sub_id}/complete [post]
func (h *TaskHandler) CompleteSubtask(c *fiber.Ctx) error {
	taskID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid task ID",
		))
	}

	subtaskID, err := uuid.Parse(c.Params("sub_id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid subtask ID",
		))
	}

	updates := map[string]interface{}{
		"status": models.TaskStatusCompleted,
	}

	if err := h.taskService.UpdateSubtask(taskID, subtaskID, updates); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			err.Error(),
		))
	}

	subtask, _ := h.taskService.GetTaskByID(subtaskID)
	return c.JSON(subtask)
}
```

---

## 2. Dependency/Flow Handlers

**Dosya:** `internal/handlers/dependency_handler.go`

```go
package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/ozlucodes/focusflow/internal/models"
	"github.com/ozlucodes/focusflow/internal/services"
)

type DependencyHandler struct {
	flowService services.FlowService
}

func NewDependencyHandler(flowService services.FlowService) *DependencyHandler {
	return &DependencyHandler{flowService: flowService}
}

type AddDependencyRequest struct {
	BlockerTaskID uuid.UUID `json:"blocker_task_id" validate:"required"`
}

// AddDependency adds a dependency between tasks
// @Summary Add dependency
// @Tags dependencies
// @Accept json
// @Produce json
// @Param id path string true "Blocked task ID"
// @Param request body AddDependencyRequest true "Blocker task ID"
// @Success 201
// @Failure 400 {object} models.ErrorResponse
// @Router /api/tasks/{id}/dependencies [post]
func (h *DependencyHandler) AddDependency(c *fiber.Ctx) error {
	blockedID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid task ID",
		))
	}

	var req AddDependencyRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid request body",
		))
	}

	if err := h.flowService.AddDependency(req.BlockerTaskID, blockedID); err != nil {
		if errResp, ok := err.(*models.ErrorResponse); ok {
			return c.Status(400).JSON(errResp)
		}
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			err.Error(),
		))
	}

	return c.Status(201).JSON(fiber.Map{"message": "Dependency added"})
}

// RemoveDependency removes a dependency
// @Summary Remove dependency
// @Tags dependencies
// @Produce json
// @Param id path string true "Task ID"
// @Param dep_id path string true "Dependency ID (blocker_task_id)"
// @Success 204
// @Router /api/tasks/{id}/dependencies/{dep_id} [delete]
func (h *DependencyHandler) RemoveDependency(c *fiber.Ctx) error {
	blockedID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid task ID",
		))
	}

	blockerID, err := uuid.Parse(c.Params("dep_id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid dependency ID",
		))
	}

	if err := h.flowService.RemoveDependency(blockerID, blockedID); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			err.Error(),
		))
	}

	return c.SendStatus(204)
}

// GetDependencies returns all dependencies for a task
// @Summary Get dependencies
// @Tags dependencies
// @Produce json
// @Param id path string true "Task ID"
// @Success 200 {array} models.TaskDependency
// @Router /api/tasks/{id}/dependencies [get]
func (h *DependencyHandler) GetDependencies(c *fiber.Ctx) error {
	taskID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid task ID",
		))
	}

	deps, err := h.flowService.GetDependencies(taskID)
	if err != nil {
		return c.Status(500).JSON(models.NewErrorResponse(
			"INTERNAL_ERROR",
			err.Error(),
		))
	}

	return c.JSON(deps)
}

// GetBlockedBy returns tasks that are blocking this task
// @Summary Get blocked by
// @Tags dependencies
// @Produce json
// @Param id path string true "Task ID"
// @Success 200 {array} services.FlowTask
// @Router /api/tasks/{id}/blocked-by [get]
func (h *DependencyHandler) GetBlockedBy(c *fiber.Ctx) error {
	taskID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid task ID",
		))
	}

	blockedBy, err := h.flowService.GetBlockedBy(taskID)
	if err != nil {
		return c.Status(500).JSON(models.NewErrorResponse(
			"INTERNAL_ERROR",
			err.Error(),
		))
	}

	return c.JSON(blockedBy)
}

// GetBlocks returns tasks that are blocked by this task
// @Summary Get blocks
// @Tags dependencies
// @Produce json
// @Param id path string true "Task ID"
// @Success 200 {array} services.FlowTask
// @Router /api/tasks/{id}/blocks [get]
func (h *DependencyHandler) GetBlocks(c *fiber.Ctx) error {
	taskID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid task ID",
		))
	}

	blocks, err := h.flowService.GetBlocks(taskID)
	if err != nil {
		return c.Status(500).JSON(models.NewErrorResponse(
			"INTERNAL_ERROR",
			err.Error(),
		))
	}

	return c.JSON(blocks)
}

// GetFlowChain returns the flow chain for a task
// @Summary Get flow chain
// @Tags dependencies
// @Produce json
// @Param id path string true "Task ID"
// @Success 200 {object} services.FlowResponse
// @Router /api/tasks/{id}/flow [get]
func (h *DependencyHandler) GetFlowChain(c *fiber.Ctx) error {
	taskID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid task ID",
		))
	}

	flow, err := h.flowService.GetFlowChain(taskID)
	if err != nil {
		return c.Status(500).JSON(models.NewErrorResponse(
			"INTERNAL_ERROR",
			err.Error(),
		))
	}

	return c.JSON(flow)
}
```

---

## 3. Dashboard Handlers

**Dosya:** `internal/handlers/dashboard_handler.go`

```go
package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/ozlucodes/focusflow/internal/services"
)

type DashboardHandler struct {
	dashboardService services.DashboardService
}

func NewDashboardHandler(dashboardService services.DashboardService) *DashboardHandler {
	return &DashboardHandler{dashboardService: dashboardService}
}

// GetDashboard returns the dashboard data
// @Summary Get dashboard
// @Tags dashboard
// @Produce json
// @Success 200 {object} services.DashboardResponse
// @Router /api/dashboard [get]
func (h *DashboardHandler) GetDashboard(c *fiber.Ctx) error {
	userID := c.Locals("userID").(uuid.UUID)

	dashboard, err := h.dashboardService.GetDashboard(userID)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Failed to get dashboard data",
		})
	}

	return c.JSON(dashboard)
}

// GetStats returns dashboard statistics
// @Summary Get stats
// @Tags dashboard
// @Produce json
// @Success 200 {object} services.DashboardStats
// @Router /api/dashboard/stats [get]
func (h *DashboardHandler) GetStats(c *fiber.Ctx) error {
	userID := c.Locals("userID").(uuid.UUID)

	stats, err := h.dashboardService.GetStats(userID)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Failed to get stats",
		})
	}

	return c.JSON(stats)
}

// GetTodayTasks returns today's tasks
// @Summary Get today's tasks
// @Tags dashboard
// @Produce json
// @Success 200 {object} services.TodayTasksResponse
// @Router /api/dashboard/today [get]
func (h *DashboardHandler) GetTodayTasks(c *fiber.Ctx) error {
	userID := c.Locals("userID").(uuid.UUID)

	tasks, err := h.dashboardService.GetTodayTasks(userID)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Failed to get today's tasks",
		})
	}

	return c.JSON(tasks)
}
```

---

## 4. Tag Handlers

**Dosya:** `internal/handlers/tag_handler.go`

```go
package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/ozlucodes/focusflow/internal/models"
	"github.com/ozlucodes/focusflow/internal/repository"
)

type TagHandler struct {
	tagRepo repository.TagRepository
}

func NewTagHandler(tagRepo repository.TagRepository) *TagHandler {
	return &TagHandler{tagRepo: tagRepo}
}

// CreateTag creates a new tag
// @Summary Create tag
// @Tags tags
// @Accept json
// @Produce json
// @Param tag body models.Tag true "Tag object"
// @Success 201 {object} models.Tag
// @Router /api/tags [post]
func (h *TagHandler) CreateTag(c *fiber.Ctx) error {
	var tag models.Tag
	if err := c.BodyParser(&tag); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid request body",
		))
	}

	userID := c.Locals("userID").(uuid.UUID)
	tag.UserID = userID

	if err := h.tagRepo.Create(&tag); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			err.Error(),
		))
	}

	return c.Status(201).JSON(tag)
}

// GetTags returns all tags for the user
// @Summary Get tags
// @Tags tags
// @Produce json
// @Success 200 {array} models.Tag
// @Router /api/tags [get]
func (h *TagHandler) GetTags(c *fiber.Ctx) error {
	userID := c.Locals("userID").(uuid.UUID)

	tags, err := h.tagRepo.GetByUserID(userID)
	if err != nil {
		return c.Status(500).JSON(models.NewErrorResponse(
			"INTERNAL_ERROR",
			err.Error(),
		))
	}

	return c.JSON(tags)
}

// AssignTagToTask assigns a tag to a task
// @Summary Assign tag to task
// @Tags tags
// @Produce json
// @Param id path string true "Task ID"
// @Param tag_id path string true "Tag ID"
// @Success 201
// @Router /api/tasks/{id}/tags/{tag_id} [post]
func (h *TagHandler) AssignTagToTask(c *fiber.Ctx) error {
	taskID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid task ID",
		))
	}

	tagID, err := uuid.Parse(c.Params("tag_id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid tag ID",
		))
	}

	if err := h.tagRepo.AssignToTask(taskID, tagID); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			err.Error(),
		))
	}

	return c.Status(201).JSON(fiber.Map{"message": "Tag assigned"})
}

// RemoveTagFromTask removes a tag from a task
// @Summary Remove tag from task
// @Tags tags
// @Produce json
// @Param id path string true "Task ID"
// @Param tag_id path string true "Tag ID"
// @Success 204
// @Router /api/tasks/{id}/tags/{tag_id} [delete]
func (h *TagHandler) RemoveTagFromTask(c *fiber.Ctx) error {
	taskID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid task ID",
		))
	}

	tagID, err := uuid.Parse(c.Params("tag_id"))
	if err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			"Invalid tag ID",
		))
	}

	if err := h.tagRepo.RemoveFromTask(taskID, tagID); err != nil {
		return c.Status(400).JSON(models.NewErrorResponse(
			models.ErrCodeValidationFailed,
			err.Error(),
		))
	}

	return c.SendStatus(204)
}
```

---

## Checklist

- [x] `internal/handlers/task_handler.go` oluşturuldu
- [x] `internal/handlers/dependency_handler.go` oluşturuldu
- [x] `internal/handlers/dashboard_handler.go` oluşturuldu
- [x] `internal/handlers/tag_handler.go` oluşturuldu
- [x] `internal/handlers/routes.go` oluşturuldu
- [x] `main.go` güncellendi (handler ve servis bağımlılıkları eklendi)
- [ ] Tüm handler'lar test edildi
