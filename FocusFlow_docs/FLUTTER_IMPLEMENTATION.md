# FocusFlow - Flutter Implementation Plan

## Proje Özeti
FocusFlow için Flutter mobil uygulaması, Go backend API'i ile konuşarak görev yönetimi, bağımlılık takibi ve Pomodoro tarzı focus timer özelliklerini sunacak.

---

## 1. Proje Kurulumu

### 1.1 Flutter Projesi Oluşturma
```bash
flutter create focusflow_app
cd focusflow_app
```

### 1.2 Gerekli Paketler (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.4.0

  # HTTP Client & API
  dio: ^5.4.0
  retrofit: ^4.0.0
  json_annotation: ^4.8.1

  # Local Storage
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0

  # Navigation
  go_router: ^13.0.0

  # UI Components
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  sliver_tools: ^0.2.12

  # Date/Time
  intl: ^0.19.0
  timeago: ^3.6.0

  # Animations
  animations: ^2.0.11

  # Icons
  google_fonts: ^6.1.0
  material_symbols: ^0.0.1

  # Timer
  timer_builder: ^2.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.8
  json_serializable: ^6.7.1
  retrofit_generator: ^8.0.6
  flutter_lints: ^3.0.1
```

---

## 2. Proje Yapısı

```
lib/
├── main.dart
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   ├── api_constants.dart
│   │   └── asset_constants.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── text_theme.dart
│   ├── router/
│   │   └── app_router.dart
│   ├── network/
│   │   ├── api_client.dart
│   │   ├── dio_interceptors.dart
│   │   └── api_exceptions.dart
│   └── storage/
│       ├── secure_storage_service.dart
│       └── shared_prefs_service.dart
├── data/
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── task_model.dart
│   │   ├── focus_session_model.dart
│   │   ├── dashboard_model.dart
│   │   ├── tag_model.dart
│   │   ├── dependency_model.dart
│   │   └── error_response_model.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── task_repository.dart
│   │   ├── focus_repository.dart
│   │   ├── dashboard_repository.dart
│   │   └── tag_repository.dart
│   └── datasources/
│       ├── auth_datasource.dart
│       ├── task_datasource.dart
│       ├── focus_datasource.dart
│       └── dashboard_datasource.dart
├── domain/
│   ├── entities/
│   │   ├── user.dart
│   │   ├── task.dart
│   │   ├── focus_session.dart
│   │   └── dashboard.dart
│   └── usecases/
│       ├── auth/
│       │   ├── login_usecase.dart
│       │   ├── register_usecase.dart
│       │   └── logout_usecase.dart
│       ├── task/
│       │   ├── get_tasks_usecase.dart
│       │   ├── create_task_usecase.dart
│       │   ├── complete_task_usecase.dart
│       │   └── get_task_detail_usecase.dart
│       └── focus/
│           ├── start_session_usecase.dart
│           ├── pause_session_usecase.dart
│           └── complete_session_usecase.dart
└── presentation/
    ├── providers/
    │   ├── auth_provider.dart
    │   ├── task_provider.dart
    │   ├── focus_provider.dart
    │   └── dashboard_provider.dart
    ├── screens/
    │   ├── splash/
    │   │   └── splash_screen.dart
    │   ├── auth/
    │   │   ├── login_screen.dart
    │   │   └── register_screen.dart
    │   ├── dashboard/
    │   │   └── dashboard_screen.dart
    │   ├── task/
    │   │   ├── task_list_screen.dart
    │   │   ├── task_detail_screen.dart
    │   │   ├── add_task_screen.dart
    │   │   └── flow_screen.dart
    │   ├── focus/
    │   │   └── focus_timer_screen.dart
    │   └── profile/
    │       └── profile_screen.dart
    ├── widgets/
    │   ├── common/
    │   │   ├── app_button.dart
    │   │   ├── app_input.dart
    │   │   ├── app_loading.dart
    │   │   └── task_card.dart
    │   ├── focus/
    │   │   ├── timer_display.dart
    │   │   └── timer_controls.dart
    │   └── task/
    │       ├── priority_badge.dart
    │       ├── dependency_chips.dart
    │       └── subtask_item.dart
    └── dialogs/
        ├── add_task_bottom_sheet.dart
        ├── dependency_picker.dart
        └── recurrence_options.dart
```

---

## 3. UI Tasarım Sistemi (Design Tokens)

### 3.1 Renk Paleti (app_colors.dart)
```dart
class AppColors {
  // Primary
  static const Color primary = Color(0xFF135BEC);
  static const Color primaryDark = Color(0xFF0F4BC4);
  static const Color primaryLight = Color(0xFF38BDF8);

  // Background
  static const Color backgroundLight = Color(0xFFF6F6F8);
  static const Color backgroundDark = Color(0xFF000000); // True Black
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceBorder = Color(0xFF333333);

  // Accents
  static const Color accentCoral = Color(0xFFFF5252); // Critical Priority
  static const Color accentOrange = Color(0xFFFF9800); // High Priority
  static const Color accentGreen = Color(0xFF69F0AE);  // Complete
  static const Color accentAmber = Color(0xFFFFB74D);  // Warning

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF92A4C9);
  static const Color textTertiary = Color(0xFF6B7280);

  // Status Colors
  static const Color statusPending = Color(0xFF2196F3);
  static const Color statusActive = Color(0xFF135BEC);
  static const Color statusBlocked = Color(0xFFFF9800);
  static const Color statusCompleted = Color(0xFF4CAF50);

  // Priority Colors
  static const Map<int, Color> priorityColors = {
    1: Color(0xFFFF5252), // Critical - Coral
    2: Color(0xFFFF9800), // High - Orange
    3: Color(0xFF2196F3), // Medium - Blue
    4: Color(0xFF4CAF50), // Low - Green
    5: Color(0xFF9E9E9E), // Minimal - Gray
  };
}
```

### 3.2 Typography (text_theme.dart)
```dart
class AppTextTheme {
  static const String fontFamily = 'Inter';

  static TextTheme lightTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.25,
    ),
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.normal,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.normal,
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    ),
  );
}
```

---

## 4. Data Models

### 4.1 User Model
```dart
@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String timezone;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.timezone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
```

### 4.2 Task Model
```dart
enum TaskStatus { pending, active, blocked, completed, archived }
enum TaskPriority { critical(1), high(2), medium(3), low(4), minimal(5) }
enum RecurrenceRule { daily, weekly, weekdays, monthly }

@JsonSerializable()
class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final TaskStatus status;
  final int priority;
  final DateTime? dueDate;
  final bool isRecurring;
  final String? recurrenceRule;
  final DateTime? recurrenceEnd;
  final String? parentId;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TaskModel> subtasks;
  final List<DependencyModel> blockedBy;
  final List<TagModel> tags;

  // Computed properties
  bool get isCompleted => status == TaskStatus.completed;
  bool get isBlocked => status == TaskStatus.blocked;
  bool get isActive => status == TaskStatus.active;
  bool get isSubtask => parentId != null;
  bool get hasSubtasks => subtasks.isNotEmpty;

  String get priorityLabel {
    switch (TaskPriority.values.firstWhere(
      (p) => p.value == priority,
      orElse: () => TaskPriority.medium,
    )) {
      case TaskPriority.critical: return 'Critical';
      case TaskPriority.high: return 'High';
      case TaskPriority.medium: return 'Medium';
      case TaskPriority.low: return 'Low';
      case TaskPriority.minimal: return 'Minimal';
    }
  }

  Color get priorityColor => AppColors.priorityColors[priority] ?? AppColors.statusPending;

  double get progress {
    if (subtasks.isEmpty) return 0;
    final completed = subtasks.where((s) => s.isCompleted).length;
    return completed / subtasks.length;
  }

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.isRecurring,
    this.recurrenceRule,
    this.recurrenceEnd,
    this.parentId,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.subtasks = const [],
    this.blockedBy = const [],
    this.tags = const [],
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => _$TaskModelFromJson(json);
  Map<String, dynamic> toJson() => _$TaskModelToJson(this);
}

enum TaskPriority {
  critical(1),
  high(2),
  medium(3),
  low(4),
  minimal(5);

  final int value;
  const TaskPriority(this.value);
}
```

### 4.3 Focus Session Model
```dart
enum SessionStatus { running, completed, cancelled, paused }

@JsonSerializable()
class FocusSessionModel {
  final String id;
  final String? taskId;
  final String userId;
  final int duration; // minutes
  final SessionStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime? pausedAt;
  final int totalPaused; // seconds
  final DateTime createdAt;

  // Computed
  bool get isRunning => status == SessionStatus.running;
  bool get isPaused => status == SessionStatus.paused;
  bool get isCompleted => status == SessionStatus.completed;

  int get remainingSeconds {
    if (completedAt != null) return 0;
    final elapsed = DateTime.now().difference(startedAt).inSeconds - totalPaused;
    final totalSeconds = duration * 60;
    return (totalSeconds - elapsed).clamp(0, totalSeconds);
  }

  int get actualDuration {
    final pausedMinutes = totalPaused ~/ 60;
    return (duration - pausedMinutes).clamp(0, duration);
  }

  double get progress {
    if (completedAt != null) return 1.0;
    final totalSeconds = duration * 60;
    final elapsed = totalSeconds - remainingSeconds;
    return elapsed / totalSeconds;
  }

  FocusSessionModel({
    required this.id,
    this.taskId,
    required this.userId,
    required this.duration,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.pausedAt,
    required this.totalPaused,
    required this.createdAt,
  });

  factory FocusSessionModel.fromJson(Map<String, dynamic> json) =>
      _$FocusSessionModelFromJson(json);
  Map<String, dynamic> toJson() => _$FocusSessionModelToJson(this);
}
```

### 4.4 Dashboard Models
```dart
@JsonSerializable()
class DashboardStats {
  final int todayTotal;
  final int todayCompleted;
  final int todayRemaining;
  final double progressPercent;
  final int weeklyFocusMinutes;

  DashboardStats({
    required this.todayTotal,
    required this.todayCompleted,
    required this.todayRemaining,
    required this.progressPercent,
    required this.weeklyFocusMinutes,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardStatsToJson(this);
}

@JsonSerializable()
class DashboardResponse {
  final String greeting;
  final String userName;
  final String date;
  final String weekday;
  final DashboardStats stats;
  final ActiveTaskSummary? activeTask;
  final NextUpTask? nextUp;

  DashboardResponse({
    required this.greeting,
    required this.userName,
    required this.date,
    required this.weekday,
    required this.stats,
    this.activeTask,
    this.nextUp,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) =>
      _$DashboardResponseFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardResponseToJson(this);
}
```

---

## 5. API Entegrasyonu

### 5.1 API Endpoints (api_constants.dart)
```dart
class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String refreshToken = '/api/auth/refresh';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/me';

  // Tasks
  static const String tasks = '/api/tasks';
  static String taskDetail(String id) => '/api/tasks/$id';
  static String taskComplete(String id) => '/api/tasks/$id/complete';
  static String taskActivate(String id) => '/api/tasks/$id/activate';
  static String taskSubtasks(String id) => '/api/tasks/$id/subtasks';
  static String taskDependencies(String id) => '/api/tasks/$id/dependencies';
  static String taskFlow(String id) => '/api/tasks/$id/flow';
  static String taskBlockedBy(String id) => '/api/tasks/$id/blocked-by';
  static String taskBlocks(String id) => '/api/tasks/$id/blocks';

  // Focus
  static const String focusSessions = '/api/focus/sessions';
  static String focusSession(String id) => '/api/focus/sessions/$id';
  static String sessionComplete(String id) => '/api/focus/sessions/$id/complete';
  static String sessionCancel(String id) => '/api/focus/sessions/$id/cancel';
  static String sessionPause(String id) => '/api/focus/sessions/$id/pause';
  static String sessionResume(String id) => '/api/focus/sessions/$id/resume';
  static const String focusStats = '/api/focus/stats';

  // Dashboard
  static const String dashboard = '/api/dashboard';
  static const String dashboardStats = '/api/dashboard/stats';
  static const String dashboardToday = '/api/dashboard/today';

  // Tags
  static const String tags = '/api/tags';
}
```

### 5.2 API Client (dio_interceptors.dart)
```dart
class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;

  AuthInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Try to refresh token
      try {
        final refreshToken = await _storage.getRefreshToken();
        if (refreshToken != null) {
          final dio = Dio();
          final response = await dio.post(
            '${ApiConstants.baseUrl}${ApiConstants.refreshToken}',
            data: {'refresh_token': refreshToken},
          );

          final newToken = response.data['access_token'];
          await _storage.saveAccessToken(newToken);

          // Retry original request
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await dio.fetch(opts);
          handler.resolve(retryResponse);
          return;
        }
      } catch (e) {
        // Logout user
      }
    }
    handler.next(err);
  }
}
```

---

## 6. Screens & Features

### 6.1 Splash Screen (splash_screen.dart)
**Referans:** `splash.html`

**Özellikler:**
- Logo animasyonu (fluid F shape with gradient)
- Ambient glow background effect
- Loading progress bar animation
- Otomatik token kontrolü ve yönlendirme

**State:**
```dart
enum SplashState {
  loading,
  authenticated,
  unauthenticated,
}
```

### 6.2 Dashboard Screen (dashboard_screen.dart)
**Referans:** `page_1.html`

**Özellikler:**
- Header: Avatar + "Good Morning/Afternoon/Evening" + Date
- Progress bar: Bugünün tamamlanma oranı
- Task listesi (swipe-to-complete desteği)
- Priority badge (Critical = Coral, High = Orange, vb.)
- Blocked task indicator (orange "Blocked" badge)
- Completed tasks section (opacity düşük, strikethrough)
- FAB (Floating Action Button) - Yeni task ekleme
- Bottom navigation (Today, Calendar, Flow, Profile)

**Widget'lar:**
- `TaskCard`: Swipe gesture, checkbox, priority indicator
- `ProgressHeader`: Progress bar + "X tasks to go"
- `TaskListFilter`: Status/priority filtreleme

### 6.3 Flow Screen (flow_screen.dart)
**Referans:** `page_2.html`

**Özellikler:**
- Timeline view (vertical connector line)
- Active task card (glowing primary border)
- Locked task card (grayscale, lock icon)
- Dependency tooltip ("Locked until X is done")
- Previous completed task (opacity düşük, check icon)
- Next tasks (ghost cards)

**Widget'lar:**
- `FlowTimelineNode`: Timeline node (active/locked/completed)
- `FlowTaskCard`: Task card with state-specific styling
- `DependencyTooltip`: Lock reason tooltip

### 6.4 Add Task Bottom Sheet (add_task_screen.dart)
**Referans:** `page_3.html`

**Özellikler:**
- Draggable bottom sheet
- Large title input (borderless, placeholder: "What needs to be done?")
- Description textarea
- Recurrence chips (Daily, Weekdays, Custom)
- Toolbar icons: Due date, Priority, Dependency, Repeat
- Submit button (FAB-style arrow)

**Widget'lar:**
- `RecurrenceChips`: Horizontal scrolling chips
- `TaskToolbar`: Icon toolbar with active states
- `DatePickerModal`: Custom date picker
- `PriorityPicker`: Priority selector
- `DependencyPicker`: Task dependency selector

### 6.5 Task Detail Screen (task_detail_screen.dart)
**Referans:** `page_4.html`

**Özellikler:**
- Back button + More options
- Tag badges
- Priority badge
- Task title (large, bold)
- Meta info: Due time, Project folder
- Description card
- Subtasks checklist
- Dependency graph (timeline view: Blocked By → Current → Blocks)
- Sticky action bar: "Start Focus Timer (25m)"

**Widget'lar:**
- `TagBadge`: Clickable tag with icon
- `SubtaskChecklist`: Expandable subtasks
- `DependencyGraph`: Timeline visualization
- `FocusTimerButton`: Sticky CTA button

### 6.6 Focus Timer Screen (focus_timer_screen.dart)

**Özellikler:**
- Circular countdown timer
- Current task display
- Play/Pause/Stop controls
- Session progress indicator
- Skip/Complete buttons
- Background notification support
- Phone wake lock (keep screen on)

**Widget'lar:**
- `CircularTimer`: Animated circular progress
- `TimerControls`: Play/Pause/Stop buttons
- `SessionInfo`: Task name, duration
- `TimerNotification`: Background notification

### 6.7 Login/Register Screens

**Login Features:**
- Email input
- Password input (show/hide)
- "Remember me" checkbox
- "Forgot password" link
- Sign in button
- "Don't have an account? Sign up"

**Register Features:**
- Full name input
- Email input
- Password input with strength indicator
- Confirm password input
- Terms checkbox
- Create account button
- "Already have an account? Sign in"

---

## 7. State Management (Riverpod)

### 7.1 Auth Provider
```dart
@riverpod
class Auth extends _$Auth {
  @override
  AuthState build() {
    return AuthState.initial();
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ref.read(authRepositoryProvider).login(
        LoginRequest(email: email, password: password),
      );
      await _storage.saveTokens(response.accessToken, response.refreshToken);
      state = AuthState.authenticated(response.user);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> logout() async {
    await _storage.clearTokens();
    state = AuthState.unauthenticated();
  }
}
```

### 7.2 Task Provider
```dart
@riverpod
class Tasks extends _$Tasks {
  @override
  TaskState build() {
    return TaskState.initial();
  }

  Future<void> loadTasks({TaskStatus? status, int? priority}) async {
    state = state.copyWith(isLoading: true);
    try {
      final tasks = await ref.read(taskRepositoryProvider).getTasks(
        status: status,
        priority: priority,
      );
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> completeTask(String taskId) async {
    await ref.read(taskRepositoryProvider).completeTask(taskId);
    await loadTasks(); // Refresh list
  }

  Future<void> activateTask(String taskId) async {
    await ref.read(taskRepositoryProvider).activateTask(taskId);
    await loadTasks();
  }
}
```

### 7.3 Focus Provider
```dart
@riverpod
class Focus extends _$Focus {
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  FocusState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return FocusState.initial();
  }

  Future<void> startSession(String? taskId, int duration) async {
    final session = await ref.read(focusRepositoryProvider).startSession(
      taskId: taskId,
      duration: duration,
    );
    _remainingSeconds = duration * 60;
    state = FocusState.active(session);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        state = state.copyWith(remainingSeconds: _remainingSeconds);
      } else {
        completeSession();
      }
    });
  }

  Future<void> pauseSession() async {
    _timer?.cancel();
    await ref.read(focusRepositoryProvider).pauseSession(state.session!.id);
    state = FocusState.paused(state.session!);
  }

  Future<void> resumeSession() async {
    await ref.read(focusRepositoryProvider).resumeSession(state.session!.id);
    state = FocusState.active(state.session!);
    _startTimer();
  }

  Future<void> completeSession() async {
    _timer?.cancel();
    await ref.read(focusRepositoryProvider).completeSession(state.session!.id);
    state = FocusState.completed();
  }
}
```

---

## 8. Navigation (GoRouter)

### 8.1 Route Yapısı
```dart
final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final auth = state.redirectedWhenAuthenticated;
    // Token kontrolü ve redirect logic
  },
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: SplashScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: RegisterScreen(),
      ),
    ),
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: DashboardScreen(),
      ),
    ),
    GoRoute(
      path: '/flow',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: FlowScreen(),
      ),
    ),
    GoRoute(
      path: '/tasks/:id',
      pageBuilder: (context, state) {
        final taskId = state.pathParameters['id']!;
        return MaterialPage(
          key: state.pageKey,
          child: TaskDetailScreen(taskId: taskId),
        );
      },
    ),
    GoRoute(
      path: '/focus',
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: FocusTimerScreen(),
      ),
    ),
  ],
);
```

---

## 9. Common Widgets

### 9.1 Task Card Widget
```dart
class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final bool swipeable;

  const TaskCard({
    required this.task,
    required this.onTap,
    required this.onComplete,
    this.swipeable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await onComplete();
          return false;
        }
        return false;
      },
      background: _buildSwipeBackground(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            border: Border(
              left: BorderSide(
                color: task.priorityColor,
                width: 4,
              ),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getTaskIcon(), color: _getIconColor()),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (task.priority != 3)
                            PriorityBadge(priority: task.priority),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (task.dueDate != null)
                            _buildDueTime(),
                          if (task.isBlocked)
                            _buildBlockedBadge(),
                          if (task.hasSubtasks)
                            _buildSubtaskProgress(),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Checkbox
                _buildCheckbox(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withOpacity(0.2),
        border: Border.all(
          color: AppColors.accentGreen.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(
        Icons.check_circle,
        color: AppColors.accentGreen,
      ),
    );
  }
}
```

---

## 10. Animations

### 10.1 Splash Animations
- Logo fade-in + scale
- Ambient glow pulse
- Progress bar loading animation

### 10.2 Transitions
- Page transitions (shared element transition)
- Bottom sheet slide-up
- Task swipe reveal
- Focus timer countdown

### 10.3 Micro-interactions
- Checkbox animation
- Button press scale
- Loading shimmer
- Success/error feedback

---

## 11. Notifications

### 11.1 Local Notifications
```yaml
dependencies:
  flutter_local_notifications: ^16.3.0
```

**Notification Types:**
- Focus session complete
- Task due reminder
- Task blocked status change
- Weekly summary

### 11.2 Foreground Service
- Keep focus timer running in background
- Show persistent notification during active session
- Update notification with remaining time

---

## 12. Implementation Sırası

### Phase 1: Foundation
- [ ] Proje kurulumu ve dependencies
- [ ] Design system (colors, typography, themes)
- [ ] Routing yapısı
- [ ] API client ve interceptors
- [ ] Storage services
- [ ] Data models

### Phase 2: Authentication
- [ ] Login screen
- [ ] Register screen
- [ ] Auth provider
- [ ] Token management
- [ ] Auto-login

### Phase 3: Dashboard
- [ ] Dashboard screen
- [ ] Task list
- [ ] Task card widget
- [ ] Progress header
- [ ] Bottom navigation
- [ ] FAB

### Phase 4: Task Management
- [ ] Task detail screen
- [ ] Add task bottom sheet
- [ ] Edit task functionality
- [ ] Subtasks
- [ ] Tags

### Phase 5: Flow & Dependencies
- [ ] Flow screen
- [ ] Dependency graph
- [ ] Timeline visualization
- [ ] Blocked task indicators

### Phase 6: Focus Timer
- [ ] Focus timer screen
- [ ] Circular countdown
- [ ] Play/Pause/Stop controls
- [ ] Background service
- [ ] Notifications

### Phase 7: Polish
- [ ] Animations
- [ ] Error handling
- [ ] Loading states
- [ ] Empty states
- [ ] Settings screen
- [ ] Profile screen

---

## 13. Error Handling

### 13.1 API Error Types
```dart
enum ErrorType {
  network,
  unauthorized,
  validation,
  notFound,
  serverError,
  taskBlocked,
  cycleDetected,
  activeSession,
}
```

### 13.2 User-Friendly Messages
- Network: "Please check your connection"
- Unauthorized: "Please login again"
- Validation: "Please check your input"
- TaskBlocked: "This task has uncompleted dependencies"
- CycleDetected: "This would create a circular dependency"
- ActiveSession: "You already have an active focus session"

---

## 14. Testing

### 14.1 Unit Tests
- Model serialization/deserialization
- Repository methods
- Use cases
- Provider state changes

### 14.2 Widget Tests
- Screen rendering
- User interactions
- Navigation

### 14.3 Integration Tests
- API calls
- Authentication flow
- Task CRUD operations
- Focus timer flow

---

## 15. Deployment

### 15.1 Build Configuration
```yaml
# flutter_launcher_icons.yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#000000"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
```

### 15.2 Environment Files
```yaml
# .env.dev
API_BASE_URL=http://localhost:3000

# .env.prod
API_BASE_URL=https://api.focusflow.app
```

---

Bu doküman, backend API dokümantasyonuna ve HTML tasarım referanslarına dayanarak Flutter uygulaması için detaylı bir implementasyon planı sunmaktadır.
