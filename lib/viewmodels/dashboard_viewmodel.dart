import 'package:mobx/mobx.dart';
import '../data/repositories/task_repository.dart';
import '../data/repositories/focus_repository.dart';
import '../data/models/task_model.dart';
import 'auth_viewmodel.dart'; // for kUseMockData flag

part 'dashboard_viewmodel.g.dart';

class DashboardViewModel = _DashboardViewModelBase with _$DashboardViewModel;

abstract class _DashboardViewModelBase with Store {
  final TaskRepository _taskRepository;
  final FocusRepository _focusRepository;

  _DashboardViewModelBase(this._taskRepository, this._focusRepository);

  @observable
  bool isLoading = false;

  @observable
  String? error;

  @observable
  ObservableList<TaskModel> todayTasks = ObservableList<TaskModel>();

  @observable
  int totalTasks = 0;

  @observable
  int completedTasks = 0;

  @observable
  int weeklyFocusMinutes = 0;

  @observable
  TaskModel? activeTask;

  @computed
  int get remainingTasks => totalTasks - completedTasks;

  @computed
  double get progressPercent =>
      totalTasks > 0 ? completedTasks / totalTasks : 0.0;

  @computed
  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @computed
  String get formattedDate {
    final now = DateTime.now();
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @computed
  List<TaskModel> get priorityTasks {
    // Get top priority tasks (not completed, sorted by priority)
    return todayTasks
        .where((t) => t.status != TaskStatus.completed)
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  @computed
  List<TaskModel> get completedTasksList {
    return todayTasks.where((t) => t.status == TaskStatus.completed).toList();
  }

  @action
  Future<void> loadDashboard(String userId) async {
    isLoading = true;
    error = null;

    // Mock mode
    if (kUseMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      totalTasks = 6;
      completedTasks = 1;
      weeklyFocusMinutes = 245;
      isLoading = false;
      return;
    }

    try {
      // Load today's stats
      final stats = await _taskRepository.getTodayStats(userId);
      totalTasks = stats['total'] as int;
      completedTasks = stats['completed'] as int;

      // Load focus stats
      final focusStats = await _focusRepository.getStats();
      weeklyFocusMinutes = focusStats['weekly_focus_minutes'] as int? ?? 0;

      // Load today's tasks
      final tasks = await _taskRepository.getLocalTasks();
      todayTasks.clear();
      todayTasks.addAll(tasks);

      // Find active task
      activeTask = tasks.firstWhere(
        (t) => t.status == TaskStatus.active,
        orElse: () => tasks.firstWhere(
          (t) => t.status == TaskStatus.pending,
          orElse: () => tasks.first,
        ),
      );
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> refreshDashboard(String userId) async {
    try {
      // Fetch fresh data from API
      await _taskRepository.fetchTasks();
      await loadDashboard(userId);
    } catch (e) {
      // Silently fail, keep showing cached data
    }
  }

  @action
  Future<bool> completeTask(String taskId) async {
    try {
      await _taskRepository.completeTask(taskId);

      // Update local state
      final index = todayTasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        todayTasks[index] = todayTasks[index].copyWith(
          status: TaskStatus.completed,
          completedAt: DateTime.now(),
        );
        completedTasks++;
      }

      if (activeTask?.id == taskId) {
        // Find next pending task
        activeTask = todayTasks.firstWhere(
          (t) => t.status == TaskStatus.pending,
          orElse: () => todayTasks.first,
        );
      }

      return true;
    } catch (e) {
      error = e.toString();
      return false;
    }
  }

  @action
  void clearError() {
    error = null;
  }
}
