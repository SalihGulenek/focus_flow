# FocusFlow API Documentation

**Base URL:** `https://focusflow-vc91.onrender.com`

**Version:** 1.0.0

## Table of Contents
- [Authentication](#authentication)
- [Tasks](#tasks)
- [Subtasks](#subtasks)
- [Dependencies](#dependencies)
- [Tags](#tags)
- [Focus Sessions](#focus-sessions)
- [Dashboard](#dashboard)
- [Error Responses](#error-responses)

---

## Authentication

All endpoints (except register/login/refresh) require authentication via Bearer token in the `Authorization` header:

```
Authorization: Bearer <access_token>
```

### Register

**POST** `/api/auth/register`

Registers a new user and automatically logs them in.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "full_name": "John Doe"
}
```

**Response (201):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "full_name": "John Doe",
    "avatar_url": null,
    "timezone": "Europe/Istanbul",
    "created_at": "2026-02-03T10:30:00Z",
    "updated_at": "2026-02-03T10:30:00Z"
  }
}
```

---

### Login

**POST** `/api/auth/login`

Authenticates a user and returns tokens.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "full_name": "John Doe",
    "avatar_url": null,
    "timezone": "Europe/Istanbul",
    "created_at": "2026-02-03T10:30:00Z",
    "updated_at": "2026-02-03T10:30:00Z"
  }
}
```

---

### Refresh Token

**POST** `/api/auth/refresh`

Refreshes an expired access token using a refresh token.

**Request Body:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response (200):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "full_name": "John Doe",
    "avatar_url": null,
    "timezone": "Europe/Istanbul",
    "created_at": "2026-02-03T10:30:00Z",
    "updated_at": "2026-02-03T10:30:00Z"
  }
}
```

---

### Get Current User

**GET** `/api/auth/me`

Returns the currently authenticated user.

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "full_name": "John Doe",
  "avatar_url": "https://api.dicebear.com/7.x/avataaars/svg?seed=john",
  "timezone": "Europe/Istanbul",
  "created_at": "2026-02-03T10:30:00Z",
  "updated_at": "2026-02-03T10:30:00Z"
}
```

---

### Update Profile

**PUT** `/api/auth/profile`

Updates the user's profile information.

**Request Body:**
```json
{
  "full_name": "John Smith",
  "avatar_url": "https://example.com/avatar.jpg",
  "timezone": "America/New_York"
}
```

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "full_name": "John Smith",
  "avatar_url": "https://example.com/avatar.jpg",
  "timezone": "America/New_York",
  "created_at": "2026-02-03T10:30:00Z",
  "updated_at": "2026-02-03T11:00:00Z"
}
```

---

### Logout

**POST** `/api/auth/logout`

Logs out the current user and invalidates the token.

**Response (200):**
```json
{
  "message": "Logged out successfully"
}
```

---

## Tasks

### Get Tasks

**GET** `/api/tasks`

Returns paginated list of tasks with optional filters.

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | int | 1 | Page number |
| `limit` | int | 20 | Items per page (max 100) |
| `status` | string | - | Filter by status (PENDING, ACTIVE, BLOCKED, COMPLETED, ARCHIVED) |
| `priority` | int | - | Filter by priority (1-5) |

**Response (200):**
```json
{
  "tasks": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Complete API documentation",
      "description": "Write comprehensive API docs for the new endpoints",
      "status": "ACTIVE",
      "priority": 1,
      "due_date": "2026-02-04T10:30:00Z",
      "is_recurring": false,
      "recurrence_rule": null,
      "recurrence_end": null,
      "parent_id": null,
      "completed_at": null,
      "created_at": "2026-02-03T10:30:00Z",
      "updated_at": "2026-02-03T10:30:00Z",
      "parent": null,
      "subtasks": [],
      "dependencies": [],
      "blocked_by": [],
      "reminders": [],
      "tags": [
        {
          "id": "660e8400-e29b-41d4-a716-446655440000",
          "name": "Work",
          "color": "#2196F3"
        }
      ],
      "focus_sessions": []
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 45,
    "total_pages": 3
  }
}
```

---

### Create Task

**POST** `/api/tasks`

Creates a new task.

**Request Body:**
```json
{
  "title": "Complete API documentation",
  "description": "Write comprehensive API docs for the new endpoints",
  "priority": 1,
  "due_date": "2026-02-04T10:30:00Z",
  "status": "PENDING",
  "is_recurring": false,
  "recurrence_rule": null,
  "recurrence_end": null
}
```

**Response (201):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Complete API documentation",
  "description": "Write comprehensive API docs for the new endpoints",
  "status": "PENDING",
  "priority": 1,
  "due_date": "2026-02-04T10:30:00Z",
  "is_recurring": false,
  "recurrence_rule": null,
  "recurrence_end": null,
  "parent_id": null,
  "completed_at": null,
  "created_at": "2026-02-03T10:30:00Z",
  "updated_at": "2026-02-03T10:30:00Z"
}
```

**Task Status Values:**
- `PENDING` - Task is waiting to be started
- `ACTIVE` - Task is currently being worked on
- `BLOCKED` - Task is blocked by dependencies
- `COMPLETED` - Task is completed
- `ARCHIVED` - Task is archived

**Priority Values:**
- `1` - Critical (Red #FF5252)
- `2` - High (Orange #FF9800)
- `3` - Medium (Blue #2196F3)
- `4` - Low (Green #4CAF50)
- `5` - Minimal (Gray #9E9E9E)

**Recurrence Rule Values:**
- `DAILY` - Repeats daily
- `WEEKLY` - Repeats weekly
- `WEEKDAYS` - Repeats on weekdays
- `MONTHLY` - Repeats monthly

---

### Get Task by ID

**GET** `/api/tasks/:id`

Returns a single task with all details.

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Complete API documentation",
  "description": "Write comprehensive API docs for the new endpoints",
  "status": "ACTIVE",
  "priority": 1,
  "due_date": "2026-02-04T10:30:00Z",
  "is_recurring": false,
  "recurrence_rule": null,
  "recurrence_end": null,
  "parent_id": null,
  "completed_at": null,
  "created_at": "2026-02-03T10:30:00Z",
  "updated_at": "2026-02-03T10:30:00Z",
  "parent": null,
  "subtasks": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440002",
      "title": "Research requirements",
      "status": "COMPLETED",
      "priority": 3,
      "parent_id": "550e8400-e29b-41d4-a716-446655440001",
      "completed_at": "2026-02-02T15:00:00Z"
    }
  ],
  "dependencies": [],
  "blocked_by": [],
  "reminders": [
    {
      "id": "770e8400-e29b-41d4-a716-446655440000",
      "task_id": "550e8400-e29b-41d4-a716-446655440001",
      "remind_at": "2026-02-04T08:00:00Z",
      "is_sent": false,
      "sent_at": null
    }
  ],
  "tags": [
    {
      "id": "660e8400-e29b-41d4-a716-446655440000",
      "name": "Work",
      "color": "#2196F3"
    }
  ],
  "focus_sessions": []
}
```

---

### Update Task

**PUT** `/api/tasks/:id`

Updates an existing task.

**Request Body:**
```json
{
  "title": "Complete API documentation (Updated)",
  "description": "Write comprehensive API docs for the new endpoints",
  "status": "ACTIVE",
  "priority": 2,
  "due_date": "2026-02-05T10:30:00Z"
}
```

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Complete API documentation (Updated)",
  "description": "Write comprehensive API docs for the new endpoints",
  "status": "ACTIVE",
  "priority": 2,
  "due_date": "2026-02-05T10:30:00Z",
  "is_recurring": false,
  "recurrence_rule": null,
  "recurrence_end": null,
  "parent_id": null,
  "completed_at": null,
  "created_at": "2026-02-03T10:30:00Z",
  "updated_at": "2026-02-03T11:00:00Z"
}
```

---

### Delete Task

**DELETE** `/api/tasks/:id`

Deletes a task.

**Response (204)** - No content

---

### Complete Task

**POST** `/api/tasks/:id/complete`

Marks a task as completed.

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Complete API documentation",
  "description": "Write comprehensive API docs for the new endpoints",
  "status": "COMPLETED",
  "priority": 1,
  "due_date": "2026-02-04T10:30:00Z",
  "is_recurring": false,
  "recurrence_rule": null,
  "recurrence_end": null,
  "parent_id": null,
  "completed_at": "2026-02-03T11:00:00Z",
  "created_at": "2026-02-03T10:30:00Z",
  "updated_at": "2026-02-03T11:00:00Z"
}
```

---

### Activate Task

**POST** `/api/tasks/:id/activate`

Activates a task (sets status to ACTIVE). Returns error if task is blocked.

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Complete API documentation",
  "description": "Write comprehensive API docs for the new endpoints",
  "status": "ACTIVE",
  "priority": 1,
  "due_date": "2026-02-04T10:30:00Z",
  "is_recurring": false,
  "recurrence_rule": null,
  "recurrence_end": null,
  "parent_id": null,
  "completed_at": null,
  "created_at": "2026-02-03T10:30:00Z",
  "updated_at": "2026-02-03T11:00:00Z"
}
```

---

## Subtasks

### Get Subtasks

**GET** `/api/tasks/:id/subtasks`

Returns all subtasks for a task.

**Response (200):**
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440002",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "parent_id": "550e8400-e29b-41d4-a716-446655440001",
    "title": "Research requirements",
    "description": "Gather and document requirements",
    "status": "COMPLETED",
    "priority": 3,
    "due_date": null,
    "is_recurring": false,
    "recurrence_rule": null,
    "recurrence_end": null,
    "completed_at": "2026-02-02T15:00:00Z",
    "created_at": "2026-02-02T10:00:00Z",
    "updated_at": "2026-02-02T15:00:00Z"
  },
  {
    "id": "550e8400-e29b-41d4-a716-446655440003",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "parent_id": "550e8400-e29b-41d4-a716-446655440001",
    "title": "Create initial draft",
    "description": "Prepare first version",
    "status": "COMPLETED",
    "priority": 3,
    "due_date": null,
    "is_recurring": false,
    "recurrence_rule": null,
    "recurrence_end": null,
    "completed_at": "2026-02-02T17:00:00Z",
    "created_at": "2026-02-02T10:00:00Z",
    "updated_at": "2026-02-02T17:00:00Z"
  },
  {
    "id": "550e8400-e29b-41d4-a716-446655440004",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "parent_id": "550e8400-e29b-41d4-a716-446655440001",
    "title": "Review and refine",
    "description": "Final review and improvements",
    "status": "ACTIVE",
    "priority": 2,
    "due_date": null,
    "is_recurring": false,
    "recurrence_rule": null,
    "recurrence_end": null,
    "completed_at": null,
    "created_at": "2026-02-02T10:00:00Z",
    "updated_at": "2026-02-03T10:00:00Z"
  }
]
```

---

### Create Subtask

**POST** `/api/tasks/:id/subtasks`

Creates a new subtask for the given parent task.

**Request Body:**
```json
{
  "title": "Review and refine",
  "description": "Final review and improvements",
  "priority": 2,
  "status": "PENDING"
}
```

**Response (201):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440004",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "parent_id": "550e8400-e29b-41d4-a716-446655440001",
  "title": "Review and refine",
  "description": "Final review and improvements",
  "status": "PENDING",
  "priority": 2,
  "due_date": null,
  "is_recurring": false,
  "recurrence_rule": null,
  "recurrence_end": null,
  "completed_at": null,
  "created_at": "2026-02-03T10:00:00Z",
  "updated_at": "2026-02-03T10:00:00Z"
}
```

---

### Update Subtask

**PUT** `/api/tasks/:id/subtasks/:sub_id`

Updates a subtask.

**Request Body:**
```json
{
  "title": "Review and refine (Updated)",
  "status": "ACTIVE",
  "priority": 2
}
```

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440004",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "parent_id": "550e8400-e29b-41d4-a716-446655440001",
  "title": "Review and refine (Updated)",
  "description": "Final review and improvements",
  "status": "ACTIVE",
  "priority": 2,
  "due_date": null,
  "is_recurring": false,
  "recurrence_rule": null,
  "recurrence_end": null,
  "completed_at": null,
  "created_at": "2026-02-03T10:00:00Z",
  "updated_at": "2026-02-03T11:00:00Z"
}
```

---

### Delete Subtask

**DELETE** `/api/tasks/:id/subtasks/:sub_id`

Deletes a subtask.

**Response (204)** - No content

---

### Complete Subtask

**POST** `/api/tasks/:id/subtasks/:sub_id/complete`

Marks a subtask as completed.

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440004",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "parent_id": "550e8400-e29b-41d4-a716-446655440001",
  "title": "Review and refine",
  "description": "Final review and improvements",
  "status": "COMPLETED",
  "priority": 2,
  "due_date": null,
  "is_recurring": false,
  "recurrence_rule": null,
  "recurrence_end": null,
  "completed_at": "2026-02-03T11:00:00Z",
  "created_at": "2026-02-03T10:00:00Z",
  "updated_at": "2026-02-03T11:00:00Z"
}
```

---

## Dependencies

### Get Task Dependencies

**GET** `/api/tasks/:id/dependencies`

Returns all dependencies for a task (tasks that must be completed before this task).

**Response (200):**
```json
[
  {
    "blocker_task_id": "550e8400-e29b-41d4-a716-446655440005",
    "blocked_task_id": "550e8400-e29b-41d4-a716-446655440001",
    "created_at": "2026-02-03T10:00:00Z",
    "blocker": {
      "id": "550e8400-e29b-41d4-a716-446655440005",
      "title": "Setup project structure",
      "status": "COMPLETED",
      "priority": 1
    }
  }
]
```

---

### Add Dependency

**POST** `/api/tasks/:id/dependencies`

Adds a dependency (blocker) to a task.

**Request Body:**
```json
{
  "blocker_id": "550e8400-e29b-41d4-a716-446655440005"
}
```

**Response (201):**
```json
{
  "blocker_task_id": "550e8400-e29b-41d4-a716-446655440005",
  "blocked_task_id": "550e8400-e29b-41d4-a716-446655440001",
  "created_at": "2026-02-03T10:00:00Z"
}
```

---

### Remove Dependency

**DELETE** `/api/tasks/:id/dependencies/:dep_id`

Removes a dependency from a task.

**Response (204)** - No content

---

### Get Flow Chain

**GET** `/api/tasks/:id/flow`

Returns the full dependency chain for a task (all tasks that block this task, and all tasks this task blocks).

**Response (200):**
```json
{
  "blocks": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440006",
      "title": "Write unit tests",
      "status": "BLOCKED"
    }
  ],
  "blocked_by": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440005",
      "title": "Setup project structure",
      "status": "COMPLETED"
    }
  ]
}
```

---

### Get Blocked By

**GET** `/api/tasks/:id/blocked-by`

Returns tasks that are blocking this task.

**Response (200):**
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440005",
    "title": "Setup project structure",
    "status": "COMPLETED",
    "priority": 1
  }
]
```

---

### Get Blocks

**GET** `/api/tasks/:id/blocks`

Returns tasks that this task is blocking.

**Response (200):**
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440006",
    "title": "Write unit tests",
    "status": "BLOCKED",
    "priority": 3
  }
]
```

---

## Tags

### Get Tags

**GET** `/api/tags`

Returns all tags for the current user.

**Response (200):**
```json
[
  {
    "id": "660e8400-e29b-41d4-a716-446655440000",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Work",
    "color": "#2196F3",
    "created_at": "2026-02-03T10:00:00Z"
  },
  {
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Personal",
    "color": "#4CAF50",
    "created_at": "2026-02-03T10:00:00Z"
  },
  {
    "id": "660e8400-e29b-41d4-a716-446655440002",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Urgent",
    "color": "#F44336",
    "created_at": "2026-02-03T10:00:00Z"
  }
]
```

---

### Create Tag

**POST** `/api/tags`

Creates a new tag.

**Request Body:**
```json
{
  "name": "Learning",
  "color": "#9C27B0"
}
```

**Response (201):**
```json
{
  "id": "660e8400-e29b-41d4-a716-446655440003",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Learning",
  "color": "#9C27B0",
  "created_at": "2026-02-03T10:00:00Z"
}
```

---

### Assign Tag to Task

**POST** `/api/tasks/:id/tags/:tag_id`

Assigns a tag to a task.

**Response (201):**
```json
{
  "message": "Tag assigned"
}
```

---

### Remove Tag from Task

**DELETE** `/api/tasks/:id/tags/:tag_id`

Removes a tag from a task.

**Response (204)** - No content

---

## Focus Sessions

### Start Focus Session

**POST** `/api/focus/sessions`

Starts a new focus session (Pomodoro timer).

**Request Body:**
```json
{
  "task_id": "550e8400-e29b-41d4-a716-446655440001",
  "duration": 25
}
```

**Response (201):**
```json
{
  "id": "880e8400-e29b-41d4-a716-446655440000",
  "task_id": "550e8400-e29b-41d4-a716-446655440001",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "duration": 25,
  "status": "RUNNING",
  "started_at": "2026-02-03T10:00:00Z",
  "completed_at": null,
  "paused_at": null,
  "total_paused": 0,
  "created_at": "2026-02-03T10:00:00Z"
}
```

**Session Status Values:**
- `RUNNING` - Session is currently running
- `PAUSED` - Session is paused
- `COMPLETED` - Session completed successfully
- `CANCELLED` - Session was cancelled

---

### Get Focus Session

**GET** `/api/focus/sessions/:id`

Returns a single focus session.

**Response (200):**
```json
{
  "id": "880e8400-e29b-41d4-a716-446655440000",
  "task_id": "550e8400-e29b-41d4-a716-446655440001",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "duration": 25,
  "status": "RUNNING",
  "started_at": "2026-02-03T10:00:00Z",
  "completed_at": null,
  "paused_at": null,
  "total_paused": 0,
  "created_at": "2026-02-03T10:00:00Z"
}
```

---

### Get User Sessions

**GET** `/api/focus/sessions`

Returns all focus sessions for the current user with optional filters.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | string | Filter by status (RUNNING, PAUSED, COMPLETED, CANCELLED) |
| `task_id` | string | Filter by task ID |

**Response (200):**
```json
[
  {
    "id": "880e8400-e29b-41d4-a716-446655440000",
    "task_id": "550e8400-e29b-41d4-a716-446655440001",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "duration": 25,
    "status": "RUNNING",
    "started_at": "2026-02-03T10:00:00Z",
    "completed_at": null,
    "paused_at": null,
    "total_paused": 0,
    "created_at": "2026-02-03T10:00:00Z"
  },
  {
    "id": "880e8400-e29b-41d4-a716-446655440001",
    "task_id": "550e8400-e29b-41d4-a716-446655440002",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "duration": 50,
    "status": "COMPLETED",
    "started_at": "2026-02-02T14:00:00Z",
    "completed_at": "2026-02-02T14:50:00Z",
    "paused_at": null,
    "total_paused": 0,
    "created_at": "2026-02-02T14:00:00Z"
  }
]
```

---

### Complete Session

**POST** `/api/focus/sessions/:id/complete`

Marks a focus session as completed.

**Response (200):**
```json
{
  "id": "880e8400-e29b-41d4-a716-446655440000",
  "task_id": "550e8400-e29b-41d4-a716-446655440001",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "duration": 25,
  "status": "COMPLETED",
  "started_at": "2026-02-03T10:00:00Z",
  "completed_at": "2026-02-03T10:25:00Z",
  "paused_at": null,
  "total_paused": 0,
  "created_at": "2026-02-03T10:00:00Z"
}
```

---

### Cancel Session

**POST** `/api/focus/sessions/:id/cancel`

Cancels a focus session.

**Response (200):**
```json
{
  "id": "880e8400-e29b-41d4-a716-446655440000",
  "task_id": "550e8400-e29b-41d4-a716-446655440001",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "duration": 25,
  "status": "CANCELLED",
  "started_at": "2026-02-03T10:00:00Z",
  "completed_at": null,
  "paused_at": null,
  "total_paused": 0,
  "created_at": "2026-02-03T10:00:00Z"
}
```

---

### Pause Session

**POST** `/api/focus/sessions/:id/pause`

Pauses a running focus session.

**Response (200):**
```json
{
  "id": "880e8400-e29b-41d4-a716-446655440000",
  "task_id": "550e8400-e29b-41d4-a716-446655440001",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "duration": 25,
  "status": "PAUSED",
  "started_at": "2026-02-03T10:00:00Z",
  "completed_at": null,
  "paused_at": "2026-02-03T10:15:00Z",
  "total_paused": 0,
  "created_at": "2026-02-03T10:00:00Z"
}
```

---

### Resume Session

**POST** `/api/focus/sessions/:id/resume`

Resumes a paused focus session.

**Response (200):**
```json
{
  "id": "880e8400-e29b-41d4-a716-446655440000",
  "task_id": "550e8400-e29b-41d4-a716-446655440001",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "duration": 25,
  "status": "RUNNING",
  "started_at": "2026-02-03T10:00:00Z",
  "completed_at": null,
  "paused_at": null,
  "total_paused": 300,
  "created_at": "2026-02-03T10:00:00Z"
}
```

---

### Get Focus Stats

**GET** `/api/focus/stats`

Returns focus statistics for the current user.

**Response (200):**
```json
{
  "total_sessions": 45,
  "completed_sessions": 38,
  "total_focus_minutes": 950,
  "average_session_duration": 25,
  "longest_streak": 5,
  "today_sessions": 3,
  "today_focus_minutes": 75
}
```

---

## Dashboard

### Get Dashboard

**GET** `/api/dashboard`

Returns the main dashboard data with tasks grouped by status.

**Response (200):**
```json
{
  "active_tasks": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "title": "Complete API documentation",
      "status": "ACTIVE",
      "priority": 1,
      "due_date": "2026-02-04T10:30:00Z"
    }
  ],
  "pending_tasks": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440007",
      "title": "Design new dashboard",
      "status": "PENDING",
      "priority": 2,
      "due_date": "2026-02-10T10:30:00Z"
    }
  ],
  "blocked_tasks": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440008",
      "title": "Deploy to production",
      "status": "BLOCKED",
      "priority": 1,
      "due_date": "2026-02-04T10:30:00Z"
    }
  ],
  "completed_tasks": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440009",
      "title": "Setup project structure",
      "status": "COMPLETED",
      "priority": 1,
      "completed_at": "2026-02-02T15:00:00Z"
    }
  ],
  "recent_focus_sessions": [
    {
      "id": "880e8400-e29b-41d4-a716-446655440000",
      "duration": 25,
      "status": "COMPLETED",
      "started_at": "2026-02-03T10:00:00Z"
    }
  ]
}
```

---

### Get Dashboard Stats

**GET** `/api/dashboard/stats`

Returns dashboard statistics.

**Response (200):**
```json
{
  "total_tasks": 45,
  "active_tasks": 3,
  "pending_tasks": 12,
  "blocked_tasks": 2,
  "completed_tasks": 28,
  "overdue_tasks": 1,
  "due_today": 5,
  "due_this_week": 8,
  "total_tags": 7,
  "total_focus_time_minutes": 950
}
```

---

### Get Today's Tasks

**GET** `/api/dashboard/today`

Returns all tasks due today.

**Response (200):**
```json
{
  "today": "2026-02-03",
  "tasks": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "title": "Complete API documentation",
      "status": "ACTIVE",
      "priority": 1,
      "due_date": "2026-02-03T18:00:00Z",
      "tags": [
        {
          "id": "660e8400-e29b-41d4-a716-446655440000",
          "name": "Work",
          "color": "#2196F3"
        }
      ]
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440010",
      "title": "Daily standup meeting",
      "status": "PENDING",
      "priority": 2,
      "due_date": "2026-02-03T10:00:00Z",
      "is_recurring": true,
      "recurrence_rule": "DAILY",
      "tags": []
    }
  ]
}
```

---

## Error Responses

All errors follow this format:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "field": "field_name",
    "details": {}
  }
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_FAILED` | 400 | Request validation failed |
| `TASK_BLOCKED` | 400 | Task is blocked by dependencies |
| `CYCLE_DETECTED` | 400 | Dependency cycle would be created |
| `NOT_FOUND` | 404 | Resource not found |
| `UNAUTHORIZED` | 401 | Authentication failed or missing |
| `ACTIVE_SESSION_EXISTS` | 400 | User already has a running focus session |
| `INVALID_RECURRENCE` | 400 | Invalid recurrence rule |
| `INVALID_DURATION` | 400 | Invalid focus session duration |
| `SELF_DEPENDENCY` | 400 | Task cannot depend on itself |
| `INTERNAL_ERROR` | 500 | Internal server error |

### Example Error Response

**400 Bad Request - Validation Failed:**
```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "Email is required",
    "field": "email"
  }
}
```

**401 Unauthorized:**
```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid email or password"
  }
}
```

**400 Bad Request - Task Blocked:**
```json
{
  "error": {
    "code": "TASK_BLOCKED",
    "message": "Cannot activate task: it has uncompleted dependencies",
    "details": {
      "blocking_tasks": [
        {
          "id": "550e8400-e29b-41d4-a716-446655440005",
          "title": "Setup project structure"
        }
      ]
    }
  }
}
```

---

## Test Users

For mobile app testing, you can use these pre-seeded test accounts:

| Email | Password |
|-------|----------|
| `demo@focusflow.app` | `password123` |
| `ahmet@focusflow.app` | `password123` |
| `ayse@focusflow.app` | `password123` |
| `john@focusflow.app` | `password123` |

These accounts have pre-populated data including tasks, tags, focus sessions, and dependencies.

---

## WebSocket

**Endpoint:** `/api/ws`

The API supports WebSocket connections for real-time updates. Connect with the access token as a query parameter:

```
wss://focusflow-vc91.onrender.com/api/ws?token=<access_token>
```

WebSocket events include:
- Task created/updated/deleted
- Focus session started/paused/completed
- Dependency added/removed
- Tag assigned/removed
