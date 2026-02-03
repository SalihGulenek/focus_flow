# FocusFlow Implementation Plan

## Proje Özeti
FocusFlow, görev bağımlılıkları, tekrarlı işler, önceliklendirme ve pomodoro tarzı focus timer özelliklerine sahip kişisel proje yönetim aracı.

## Flutter Tasarım Sayfaları (UI Reference)
- `splash.html` - Splash screen (Logo + Loading)
- `page_1.html` - Dashboard (Görev listesi, Progress bar, FAB, Bottom Navigation)
- `page_2.html` - Dependencies Flow (Timeline, Locked tasks, Bağımlılık zinciri)
- `page_3.html` - Add Task Bottom Sheet (Recurrence, Priority, Tags)
- `page_4.html` - Task Detail (Subtasks, Dependency Graph, Focus Timer)

---

## Teknoloji Stack
- **Backend**: Go (Fiber framework)
- **Database**: Supabase PostgreSQL
- **ORM**: GORM
- **Frontend**: Flutter (Mobile App)
- **Cache**: Redis (Refresh tokens, Rate limiting)
- **Validation**: go-playground/validator

---

## Database Model Tasarımı (DÜZELTİLMİŞ)

### 1. Users Model (Kullanıcılar)

```go
type User struct {
    ID           uuid.UUID `gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
    Email        string    `gorm:"type:varchar(255);uniqueIndex;not null"`
    PasswordHash string    `gorm:"type:varchar(255);not null"`
    FullName     string    `gorm:"type:varchar(100)"`
    AvatarURL    string    `gorm:"type:varchar(500)"`
    Timezone     string    `gorm:"type:varchar(50);default:'Europe/Istanbul'"`
    CreatedAt    time.Time `gorm:"autoCreateTime"`
    UpdatedAt    time.Time `gorm:"autoUpdateTime"`

    // Constraints
    PasswordHash string `validate:"min=8,max=72"`
}
```

### 2. Tasks Model (Görevler) - DÜZELTİLMİŞ

```go
type Task struct {
    ID              uuid.UUID  `gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
    UserID          uuid.UUID  `gorm:"type:uuid;not null;index"`
    User            User       `gorm:"foreignKey:UserID"`
    Title           string     `gorm:"type:varchar(255);not null"`
    Description     string     `gorm:"type:text"`
    Status          TaskStatus `gorm:"type:varchar(20);not null;default:'PENDING';index"`
    Priority        int        `gorm:"type:int;not null;default:3;check:priority >= 1 AND priority <= 5"` // 1=Critical, 2=High, 3=Medium, 4=Low, 5=Minimal
    DueDate         *time.Time `gorm:"index"`
    IsRecurring     bool       `gorm:"type:boolean;not null;default:false;index"`
    RecurrenceRule  *string    `gorm:"type:varchar(100)"` // "DAILY", "WEEKLY", "WEEKDAYS", "MONTHLY", cron format
    RecurrenceEnd   *time.Time `gorm:"type:timestamp"`    // Recurring task bitiş tarihi (YENI)
    ParentID        *uuid.UUID  `gorm:"type:uuid;index"` // Subtasks için
    CompletedAt     *time.Time
    CreatedAt       time.Time  `gorm:"autoCreateTime"`
    UpdatedAt       time.Time  `gorm:"autoUpdateTime"`

    // Relationships - DÜZELTİLMİŞ
    // Self-relation için explicit foreign key
    Parent         *Task            `gorm:"constraint:OnDelete:CASCADE;foreignKey:ParentID"`
    Subtasks       []Task           `gorm:"constraint:OnDelete:CASCADE;foreignKey:ParentID"`
    Dependencies   []TaskDependency `gorm:"foreignKey:BlockedTaskID;constraint:OnDelete:CASCADE"`
    BlockedBy      []TaskDependency `gorm:"foreignKey:BlockerTaskID;constraint:OnDelete:CASCADE"`
    Reminders      []Reminder       `gorm:"foreignKey:TaskID;constraint:OnDelete:CASCADE"`
    Tags           []Tag            `gorm:"many2many:task_tags;"`
    FocusSessions  []FocusSession   `gorm:"foreignKey:TaskID;constraint:OnDelete:SET NULL"`
}

type TaskStatus string
const (
    TaskStatusPending   TaskStatus = "PENDING"   // Normal beklemede
    TaskStatusActive    TaskStatus = "ACTIVE"    // Şu anda çalışılıyor
    TaskStatusBlocked   TaskStatus = "BLOCKED"   // Bağımlılık nedeniyle kilitli
    TaskStatusCompleted TaskStatus = "COMPLETED"
    TaskStatusArchived  TaskStatus = "ARCHIVED"
)

type TaskPriority int
const (
    PriorityCritical TaskPriority = 1 // Coral (#FF5252)
    PriorityHigh     TaskPriority = 2 // Orange
    PriorityMedium   TaskPriority = 3 // Default
    PriorityLow      TaskPriority = 4 // Blue
    PriorityMinimal  TaskPriority = 5 // Gray
)

// Recurrence Rule Constants (YENI)
const (
    RecurrenceDaily   = "DAILY"
    RecurrenceWeekly  = "WEEKLY"
    RecurrenceWeekdays = "WEEKDAYS"
    RecurrenceMonthly = "MONTHLY"
)
```

### 3. TaskDependencies Model (Görev Bağımlılıkları) - DÜZELTİLMİŞ

```go
// Composite primary key için unique index
type TaskDependency struct {
    BlockerTaskID uuid.UUID `gorm:"type:uuid;primaryKey;not null"`
    Blocker       Task      `gorm:"foreignKey:BlockerTaskID;constraint:OnDelete:CASCADE"`
    BlockedTaskID uuid.UUID `gorm:"type:uuid;primaryKey;not null"`
    Blocked       Task      `gorm:"foreignKey:BlockedTaskID;constraint:OnDelete:CASCADE"`
    CreatedAt     time.Time `gorm:"autoCreateTime"`

    // Cycle prevention için constraint (database level - trigger ile)
}

// Unique index for preventing duplicate dependencies
// CREATE UNIQUE INDEX idx_task_dependency_unique ON task_dependencies(blocker_task_id, blocked_task_id);
// CHECK constraint: blocker_task_id != blocked_task_id
```

### 4. Subtasks Model (Alt Görevler - Tasks tablosu içinde)

```go
// Subtasks, Tasks tablosunun parent_id ile self-relation'ı ile yönetilir
// ParentID != nil olan task'lar subtask olarak kabul edilir
```

### 5. Reminders Model (Hatırlatmalar)

```go
type Reminder struct {
    ID        uuid.UUID `gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
    TaskID    uuid.UUID `gorm:"type:uuid;not null;index"`
    Task      Task      `gorm:"foreignKey:TaskID;constraint:OnDelete:CASCADE"`
    RemindAt  time.Time `gorm:"type:timestamp;not null;index"`
    IsSent    bool      `gorm:"type:boolean;not null;default:false;index"`
    SentAt    *time.Time
    CreatedAt time.Time `gorm:"autoCreateTime"`
}
```

### 6. Tags Model (Etiketler - Kategorizasyon)

```go
type Tag struct {
    ID        uuid.UUID `gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
    UserID    uuid.UUID `gorm:"type:uuid;not null;index"`
    User      User      `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE"`
    Name      string    `gorm:"type:varchar(50);not null"`
    Color     string    `gorm:"type:varchar(7)"` // Hex color code (örn: "#FF5733")
    CreatedAt time.Time `gorm:"autoCreateTime"`

    // Many-to-Many relationship
    Tasks     []Task    `gorm:"many2many:task_tags;"`
}

// Join table: task_tags (task_id, tag_id) - auto managed by GORM
```

### 7. FocusSessions Model (Pomodoro Tarzı Focus Timer) - DÜZELTİLMİŞ

```go
type FocusSession struct {
    ID          uuid.UUID    `gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
    TaskID      *uuid.UUID   `gorm:"type:uuid;index"` // Nullable - task silinse de session kalsın
    Task        *Task        `gorm:"foreignKey:TaskID"`
    UserID      uuid.UUID    `gorm:"type:uuid;not null;index"`
    User        User         `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE"`
    Duration    int          `gorm:"type:int;not null;default:25"` // Dakika cinsinden (default: 25)
    Status      SessionStatus `gorm:"type:varchar(20);not null;default:'RUNNING';index"`
    StartedAt   time.Time    `gorm:"type:timestamp;not null"`
    CompletedAt *time.Time
    PausedAt    *time.Time     // YENI - pause zamanı
    TotalPaused int            // YENI - toplam duraklatma süresi (saniye)
    CreatedAt   time.Time      `gorm:"autoCreateTime"`
}

type SessionStatus string
const (
    SessionStatusRunning   SessionStatus = "RUNNING"   // Timer çalışıyor
    SessionStatusCompleted SessionStatus = "COMPLETED" // Tamamlandı
    SessionStatusCancelled SessionStatus = "CANCELLED" // İptal edildi
    SessionStatusPaused    SessionStatus = "PAUSED"    // Duraklatıldı
)

// Constraint: Her kullanıcı için en fazla bir RUNNING session olabilir
// CREATE UNIQUE INDEX idx_active_focus_session ON focus_sessions(user_id, status) WHERE status = 'RUNNING';
```

---

## Ek Database Indexleri (DÜZELTİLMİŞ - YENI)

```sql
-- Performance için compound indexler
CREATE INDEX idx_tasks_status_priority ON tasks(status, priority) WHERE status != 'COMPLETED';
CREATE INDEX idx_tasks_user_due ON tasks(user_id, due_date) WHERE due_date IS NOT NULL;
CREATE INDEX idx_tasks_user_status ON tasks(user_id, status);
CREATE INDEX idx_reminders_pending ON reminders(remind_at, is_sent) WHERE is_sent = false;
CREATE INDEX idx_focus_sessions_user_status ON focus_sessions(user_id, started_at DESC) WHERE status = 'COMPLETED';

-- Task dependencies için unique constraint
CREATE UNIQUE INDEX idx_task_dependency_unique ON task_dependencies(blocker_task_id, blocked_task_id);

-- Self-reference prevention (trigger ile)
CREATE CONSTRAINT check_no_self_dependency CHECK (blocker_task_id != blocked_task_id);
```

---

## Standart Error Response Formatı (YENI)

```go
type ErrorResponse struct {
    Error ErrorDetail `json:"error"`
}

type ErrorDetail struct {
    Code    string         `json:"code"`    // TASK_BLOCKED, INVALID_INPUT, etc.
    Message string         `json:"message"`
    Details map[string]any `json:"details,omitempty"`
    Field   string         `json:"field,omitempty"` // Validation hatası için
}

// Error Codes
const (
    ErrCodeValidationFailed = "VALIDATION_FAILED"
    ErrCodeTaskBlocked      = "TASK_BLOCKED"
    ErrCodeCycleDetected    = "CYCLE_DETECTED"
    ErrCodeNotFound         = "NOT_FOUND"
    ErrCodeUnauthorized     = "UNAUTHORIZED"
    ErrCodeActiveSession    = "ACTIVE_SESSION_EXISTS"
    ErrCodeInvalidRecurrence = "INVALID_RECURRENCE"
)
```

---

## Veritabanı Şema Diagramı

```
┌─────────────────┐
│     Users       │
├─────────────────┤
│ id (PK)         │◄──────┐
│ email           │       │
│ password_hash   │       │
│ full_name       │       │
│ avatar_url      │       │
│ timezone        │       │
│ created_at      │       │
│ updated_at      │       │
└─────────────────┘       │
                           │
                           │
┌─────────────────┐       │
│     Tasks       │       │
├─────────────────┤       │
│ id (PK)         │       │
│ user_id (FK)    │───────┘
│ title           │
│ description     │
│ status          │
│ priority        │
│ due_date        │
│ is_recurring    │
│ recurrence_rule │
│ recurrence_end  │◄───────┐ (YENI)
│ parent_id (FK)  │        │ (Subtasks)
│ completed_at    │        │
└─────────────────┘        │
         │                 │
         │ M:N             │
┌─────────────────┐        │
│TaskDependencies │        │
├─────────────────┤        │
│ blocker_task_id │────────┘
│ blocked_task_id │────────┐
│ (unique index)  │        │
└─────────────────┘        │
                           │
┌─────────────────┐        │
│   Reminders     │        │
├─────────────────┤        │
│ id (PK)         │        │
│ task_id (FK)    │────────┘
│ remind_at       │
│ is_sent         │
│ sent_at         │
└─────────────────┘

┌─────────────────┐
│      Tags       │
├─────────────────┤
│ id (PK)         │◄──────┐
│ user_id (FK)    │       │
│ name            │       │
│ color           │       │
└─────────────────┘       │
         │ M:N            │
┌─────────────────┐       │
│   task_tags     │       │
│ (join table)    │───────┘
└─────────────────┘

┌─────────────────┐
│  FocusSessions  │
├─────────────────┤
│ id (PK)         │
│ task_id (FK)    │────────┐ (nullable)
│ user_id (FK)    │───────┐│
│ duration        │        ││
│ status          │        ││
│ started_at      │        ││
│ completed_at    │        ││
│ paused_at       │        ││ (YENI)
│ total_paused    │        ││ (YENI)
└─────────────────┘        ││
                           │└───> Tasks (SET NULL)
                           └────> Users (CASCADE)
```

---

## Kritik İş Mantığı (Business Logic - DÜZELTİLMİŞ)

### 1. Görev Tamamlama Akışı (Transaction ile)
```go
func (s *TaskService) CompleteTask(taskID uuid.UUID) error {
    // Transaction başlat
    tx := s.db.Begin()

    // 1. Görevi completed olarak işaretle
    // 2. Subtask ise, parent'ın tüm subtask'ları tamamlandı mı kontrol et
    //    - Evet ve parent'ın diğer bağımlılıkları yoksa parent'ı da complete et
    // 3. Bu görevin engellediği diğer görevleri bul
    // 4. Her engellenen görev için:
    //    - Tüm engelleri kaldırıldı mı kontrol et
    //    - Evet ise: BLOCKED -> PENDING
    //    - Hayır ise: BLOCKED olarak kalsın
    // 5. Eğer recurring task ise:
    //    - RecurrenceEnd kontrol et
    //    - Bir sonraki occurrence'ı oluştur
    //    - Due date'i hesapla (recurrence rule'a göre)
    // 6. Commit veya Rollback

    return nil
}
```

### 2. Bağımlılık Kontrolü (YENI - Cycle Detection)
```go
func (s *FlowService) AddDependency(blockerID, blockedID uuid.UUID) error {
    // 1. Self-reference kontrolü
    if blockerID == blockedID {
        return errors.New("cannot create self-dependency")
    }

    // 2. Duplicate kontrolü
    // 3. Cycle detection (DFS ile)
    if s.wouldCreateCycle(blockerID, blockedID) {
        return ErrCycleDetected
    }

    // 4. Dependency oluştur
    // 5. Blocked task'ı BLOCKED statusüne güncelle
    return nil
}

func (s *FlowService) wouldCreateCycle(blockerID, blockedID uuid.UUID) bool {
    // Graph traversal: blockedID'den başla
    // blockerID'ye ulaşılıyor mu?
    // Evet ise cycle var!
    visited := make(map[uuid.UUID]bool)
    return s.hasCycle(blockedID, blockerID, visited)
}

func (s *FlowService) hasCycle(current, target uuid.UUID, visited map[uuid.UUID]bool) bool {
    if current == target {
        return true
    }
    if visited[current] {
        return false
    }
    visited[current] = true

    // Current task'ın engellediği task'ları bul
    // Rekürsif devam et
    return false
}
```

### 3. Focus Timer Mantığı (DÜZELTİLMİŞ)
```go
func (s *FocusService) StartSession(taskID uuid.UUID, duration int) (*FocusSession, error) {
    // Transaction başlat
    tx := s.db.Begin()

    // 1. Aktif session var mı kontrol et (SELECT FOR UPDATE)
    var existing FocusSession
    err := tx.Where("user_id = ? AND status = ?", userID, SessionStatusRunning).
        First(&existing).Error

    if err == nil {
        tx.Rollback()
        return nil, ErrActiveSessionExists
    }

    // 2. Duration validation (1-120 dakika)
    if duration < 1 || duration > 120 {
        tx.Rollback()
        return nil, ErrInvalidDuration
    }

    // 3. Yeni session oluştur
    session := &FocusSession{
        TaskID:    &taskID,
        UserID:    userID,
        Duration:  duration,
        Status:    SessionStatusRunning,
        StartedAt: time.Now(),
    }

    // 4. Task'ı ACTIVE statusüne güncelle
    // 5. Commit
    return session, nil
}

func (s *FocusService) PauseSession(sessionID uuid.UUID, userID uuid.UUID) error {
    // 1. Session'ı bul (user ownership kontrolü)
    // 2. Status PAUSED yap
    // 3. PausedAt set et
    return nil
}

func (s *FocusService) ResumeSession(sessionID uuid.UUID, userID uuid.UUID) error {
    // 1. Session'ı bul
    // 2. TotalPaused güncelle (PausedAt - şimdi)
    // 3. Status RUNNING yap
    // 4. PausedAt nil yap
    return nil
}

func (s *FocusService) CompleteSession(sessionID uuid.UUID, userID uuid.UUID) error {
    // Transaction başlat
    // 1. Session'ı bul
    // 2. Status COMPLETED yap
    // 3. CompletedAt set et
    // 4. Toplam süre = Duration - TotalPaused/60
    // 5. Dashboard stats'a ekle
    // 6. Task'ın status'ünü eski haline getir (ACTIVE -> PENDING)
    return nil
}
```

### 4. Recurring Task Logic (YENI)
```go
func (s *TaskService) CreateNextOccurrence(task *Task) error {
    if !task.IsRecurring || task.RecurrenceRule == nil {
        return nil
    }

    // RecurrenceEnd kontrolü
    if task.RecurrenceEnd != nil && task.DueDate.After(*task.RecurrenceEnd) {
        // Recurring bitti, task'ı normal task yap
        return nil
    }

    // Bir sonraki due date'i hesapla
    nextDueDate := s.calculateNextDueDate(*task.DueDate, *task.RecurrenceRule)

    // Yeni task oluştur
    newTask := &Task{
        UserID:          task.UserID,
        Title:           task.Title,
        Description:     task.Description,
        Priority:        task.Priority,
        Status:          TaskStatusPending,
        DueDate:         &nextDueDate,
        IsRecurring:     task.IsRecurring,
        RecurrenceRule:  task.RecurrenceRule,
        RecurrenceEnd:   task.RecurrenceEnd,
        ParentID:        nil,
    }

    return s.repo.Create(newTask)
}

func (s *TaskService) calculateNextDueDate(currentDue time.Time, rule string) time.Time {
    switch rule {
    case RecurrenceDaily:
        return currentDueDate.AddDate(0, 0, 1)
    case RecurrenceWeekly:
        return currentDueDate.AddDate(0, 0, 7)
    case RecurrenceWeekdays:
        // Sadece hafta içi
        next := currentDueDate.AddDate(0, 0, 1)
        for next.Weekday() == time.Saturday || next.Weekday() == time.Sunday {
            next = next.AddDate(0, 0, 1)
        }
        return next
    case RecurrenceMonthly:
        return currentDueDate.AddDate(0, 1, 0)
    default:
        // Cron format (robfig/cron ile parse)
        // ...
        return currentDueDate
    }
}
```

---

## Implementation Adımları

Ayrı Phase dokümanlarına bakınız:
- **PHASE_1_DATABASE.md** - Veritabanı kurulumu ve modeller
- **PHASE_2_REPOSITORY.md** - Repository katmanı
- **PHASE_3_SERVICE.md** - Service katmanı ve business logic
- **PHASE_4_API_HANDLERS.md** - API handler ve routes
- **PHASE_5_AUTH.md** - Authentication ve JWT
- **PHASE_6_FOCUS_TIMER.md** - Focus timer özellikleri
- **PHASE_7_DASHBOARD.md** - Dashboard ve reporting

---

## API Endpoint Tasarımları

### Auth Endpoints
```
POST   /api/auth/register        - Kullanıcı kaydı
POST   /api/auth/login           - Kullanıcı girişi
POST   /api/auth/refresh         - Token yenileme
POST   /api/auth/logout          - Logout (refresh token sil)
GET    /api/auth/me              - Mevcut kullanıcı bilgisi
PUT    /api/auth/profile         - Profil güncelleme
PUT    /api/auth/password        - Şifre değiştirme
```

### Task Endpoints (Pagination ile)
```
GET    /api/tasks?page=1&limit=20&status=PENDING&priority=1
POST   /api/tasks
GET    /api/tasks/:id
PUT    /api/tasks/:id
DELETE /api/tasks/:id
POST   /api/tasks/:id/complete
POST   /api/tasks/:id/activate
POST   /api/tasks/:id/cancel    - Active task'ı iptal et
```

### Subtask Endpoints
```
GET    /api/tasks/:id/subtasks
POST   /api/tasks/:id/subtasks
PUT    /api/tasks/:id/subtasks/:sub_id
DELETE /api/tasks/:id/subtasks/:sub_id
POST   /api/tasks/:id/subtasks/:sub_id/complete
```

### Dependency/Flow Endpoints
```
GET    /api/tasks/:id/dependencies
POST   /api/tasks/:id/dependencies
DELETE /api/tasks/:id/dependencies/:dep_id
GET    /api/tasks/:id/flow
GET    /api/tasks/:id/blocked-by
GET    /api/tasks/:id/blocks
```

### Focus Timer Endpoints
```
POST   /api/focus/sessions
GET    /api/focus/sessions?user_id=uuid&status=COMPLETED
GET    /api/focus/sessions/:id
POST   /api/focus/sessions/:id/complete
POST   /api/focus/sessions/:id/cancel
POST   /api/focus/sessions/:id/pause
POST   /api/focus/sessions/:id/resume
GET    /api/focus/stats           - Focus istatistikleri
```

### Dashboard Endpoints
```
GET    /api/dashboard
GET    /api/dashboard/stats
GET    /api/dashboard/today
```

---

## UI/API Mapping

| UI Page (Flutter/HTML) | Gerekli API Endpoints |
|------------------------|----------------------|
| **splash.html** | `GET /api/auth/me` (token check) |
| **page_1.html** (Dashboard) | `GET /api/dashboard`, `GET /api/dashboard/today`, `GET /api/tasks?page=1&limit=20` |
| **page_2.html** (Flow View) | `GET /api/tasks/:id/flow` |
| **page_3.html** (Add Task) | `POST /api/tasks`, `GET /api/tags` |
| **page_4.html** (Task Detail) | `GET /api/tasks/:id`, `GET /api/tasks/:id/subtasks`, `GET /api/focus/sessions?task_id=:id` |

---

## Responsive JSON Response Formatları

### Task List Response (Dashboard için)
```json
{
  "tasks": [
    {
      "id": "uuid",
      "title": "Finalize Design System",
      "description": "Standardize color tokens...",
      "status": "PENDING",
      "priority": 2,
      "priority_label": "High",
      "priority_color": "#FF5252",
      "due_date": "2024-10-24T10:00:00Z",
      "is_blocked": true,
      "blocked_by_count": 1,
      "blocked_by": ["Audit Legacy Components"],
      "subtasks_total": 3,
      "subtasks_completed": 1,
      "tags": [
        {"id": "uuid", "name": "Q3 UI Overhaul", "color": "#135bec"}
      ],
      "created_at": "2024-10-24T08:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 45,
    "total_pages": 3
  },
  "summary": {
    "total": 5,
    "completed": 1,
    "remaining": 4,
    "progress_percent": 20
  }
}
```

### Error Response Format
```json
{
  "error": {
    "code": "TASK_BLOCKED",
    "message": "This task cannot be started because it has 2 uncompleted dependencies",
    "details": {
      "blocked_by": [
        {"id": "uuid", "title": "Audit Legacy Components", "status": "PENDING"},
        {"id": "uuid", "title": "Setup CI/CD", "status": "ACTIVE"}
      ]
    }
  }
}
```

### Cycle Detected Error
```json
{
  "error": {
    "code": "CYCLE_DETECTED",
    "message": "Adding this dependency would create a circular dependency",
    "details": {
      "proposed": "Task A -> Task B",
      "existing_path": "Task B -> Task C -> Task A"
    }
  }
}
```
