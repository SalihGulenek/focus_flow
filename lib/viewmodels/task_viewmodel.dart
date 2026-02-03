import 'package:mobx/mobx.dart';
import '../data/repositories/task_repository.dart';
import '../data/models/task_model.dart';
import '../data/models/tag_model.dart';
import 'auth_viewmodel.dart'; // for kUseMockData flag

part 'task_viewmodel.g.dart';

class TaskViewModel = _TaskViewModelBase with _$TaskViewModel;

abstract class _TaskViewModelBase with Store {
  final TaskRepository _taskRepository;

  _TaskViewModelBase(this._taskRepository);

  @observable
  ObservableList<TaskModel> tasks = ObservableList<TaskModel>();

  @observable
  TaskModel? selectedTask;

  @observable
  ObservableList<TagModel> tags = ObservableList<TagModel>();

  @observable
  bool isLoading = false;

  @observable
  String? error;

  @observable
  TaskStatus? filterStatus;

  @observable
  int? filterPriority;

  @computed
  List<TaskModel> get filteredTasks {
    return tasks.where((task) {
      if (filterStatus != null && task.status != filterStatus) return false;
      if (filterPriority != null && task.priority != filterPriority) return false;
      return true;
    }).toList();
  }

  @computed
  List<TaskModel> get pendingTasks =>
      tasks.where((t) => t.status == TaskStatus.pending).toList();

  @computed
  List<TaskModel> get activeTasks =>
      tasks.where((t) => t.status == TaskStatus.active).toList();

  @computed
  List<TaskModel> get blockedTasks =>
      tasks.where((t) => t.status == TaskStatus.blocked).toList();

  @computed
  List<TaskModel> get completedTasks =>
      tasks.where((t) => t.status == TaskStatus.completed).toList();

  @computed
  int get totalTasks => tasks.length;

  @computed
  int get completedCount => completedTasks.length;

  @computed
  double get progressPercent =>
      totalTasks > 0 ? completedCount / totalTasks : 0.0;

  @action
  Future<void> loadTasks({bool refresh = false}) async {
    if (isLoading && !refresh) return;

    isLoading = true;
    error = null;

    // Mock mode - load mock tasks
    if (kUseMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      tasks.clear();
      tasks.addAll(_createMockTasks());
      isLoading = false;
      return;
    }

    try {
      final fetchedTasks = await _taskRepository.fetchTasks(
        status: filterStatus,
        priority: filterPriority,
      );
      tasks.clear();
      tasks.addAll(fetchedTasks);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
    }
  }

  List<TaskModel> _createMockTasks() {
    final now = DateTime.now();
    return [
      TaskModel(
        id: 'task-001',
        userId: 'mock-user-001',
        title: 'Design System Implementation',
        description: 'Implement the design system with all color tokens and typography.',
        status: TaskStatus.active,
        priority: 1,
        dueDate: now.add(const Duration(hours: 2)),
        isRecurring: false,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      ),
      TaskModel(
        id: 'task-002',
        userId: 'mock-user-001',
        title: 'Setup CI/CD Pipeline',
        description: 'Configure GitHub Actions for automated testing and deployment.',
        status: TaskStatus.pending,
        priority: 2,
        dueDate: now.add(const Duration(days: 1)),
        isRecurring: false,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
      ),
      TaskModel(
        id: 'task-003',
        userId: 'mock-user-001',
        title: 'Write API Documentation',
        description: 'Document all API endpoints with examples.',
        status: TaskStatus.blocked,
        priority: 3,
        dueDate: now.add(const Duration(days: 2)),
        isRecurring: false,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
        blockedBy: [
          TaskDependencyModel(
            blockerTaskId: 'task-002',
            blockerTitle: 'Setup CI/CD Pipeline',
            blockerStatus: TaskStatus.pending,
            createdAt: now,
          ),
        ],
      ),
      TaskModel(
        id: 'task-004',
        userId: 'mock-user-001',
        title: 'Daily Standup Notes',
        description: 'Prepare notes for daily standup meeting.',
        status: TaskStatus.pending,
        priority: 4,
        dueDate: now.add(const Duration(hours: 4)),
        isRecurring: true,
        recurrenceRule: 'WEEKDAYS',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
      ),
      TaskModel(
        id: 'task-005',
        userId: 'mock-user-001',
        title: 'Review Pull Requests',
        description: 'Review and merge pending pull requests.',
        status: TaskStatus.completed,
        priority: 2,
        dueDate: now.subtract(const Duration(hours: 2)),
        completedAt: now.subtract(const Duration(hours: 1)),
        isRecurring: false,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      ),
      TaskModel(
        id: 'task-006',
        userId: 'mock-user-001',
        title: 'Update Dependencies',
        description: 'Update all npm and Flutter packages to latest versions.',
        status: TaskStatus.pending,
        priority: 5,
        dueDate: now.add(const Duration(days: 7)),
        isRecurring: false,
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now,
      ),
    ];
  }

  @action
  Future<void> loadLocalTasks() async {
    isLoading = true;
    error = null;

    try {
      final localTasks = await _taskRepository.getLocalTasks(
        status: filterStatus,
        priority: filterPriority,
      );
      tasks.clear();
      tasks.addAll(localTasks);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> loadTask(String id) async {
    isLoading = true;
    error = null;

    // Mock mode
    if (kUseMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      selectedTask = tasks.firstWhere(
        (t) => t.id == id,
        orElse: () => _createMockTasks().firstWhere((t) => t.id == id),
      );
      isLoading = false;
      return;
    }

    try {
      selectedTask = await _taskRepository.fetchTask(id);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<bool> createTask({
    required String userId,
    required String title,
    String? description,
    int priority = 3,
    DateTime? dueDate,
    bool isRecurring = false,
    String? recurrenceRule,
    DateTime? recurrenceEnd,
    String? parentId,
    List<String>? tagIds,
    List<String>? blockerTaskIds,
  }) async {
    isLoading = true;
    error = null;

    try {
      final newTask = await _taskRepository.createTask(
        userId: userId,
        title: title,
        description: description,
        priority: priority,
        dueDate: dueDate,
        isRecurring: isRecurring,
        recurrenceRule: recurrenceRule,
        recurrenceEnd: recurrenceEnd,
        parentId: parentId,
        tagIds: tagIds,
        blockerTaskIds: blockerTaskIds,
      );

      if (parentId == null) {
        tasks.insert(0, newTask);
      }
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<bool> updateTask(String id, {
    String? title,
    String? description,
    TaskStatus? status,
    int? priority,
    DateTime? dueDate,
    bool? isRecurring,
    String? recurrenceRule,
    DateTime? recurrenceEnd,
  }) async {
    isLoading = true;
    error = null;

    try {
      final updatedTask = await _taskRepository.updateTask(
        id,
        title: title,
        description: description,
        status: status,
        priority: priority,
        dueDate: dueDate,
        isRecurring: isRecurring,
        recurrenceRule: recurrenceRule,
        recurrenceEnd: recurrenceEnd,
      );

      final index = tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        tasks[index] = updatedTask;
      }

      if (selectedTask?.id == id) {
        selectedTask = updatedTask;
      }

      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<bool> deleteTask(String id) async {
    isLoading = true;
    error = null;

    try {
      await _taskRepository.deleteTask(id);
      tasks.removeWhere((t) => t.id == id);

      if (selectedTask?.id == id) {
        selectedTask = null;
      }

      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<bool> completeTask(String id) async {
    // Mock mode
    if (kUseMockData) {
      final index = tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        final task = tasks[index];
        final completedTask = task.copyWith(
          status: TaskStatus.completed,
          completedAt: DateTime.now(),
        );
        tasks[index] = completedTask;
        if (selectedTask?.id == id) {
          selectedTask = completedTask;
        }
      }
      return true;
    }

    try {
      final completedTask = await _taskRepository.completeTask(id);

      final index = tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        tasks[index] = completedTask;
      }

      if (selectedTask?.id == id) {
        selectedTask = completedTask;
      }

      return true;
    } catch (e) {
      error = e.toString();
      return false;
    }
  }

  @action
  Future<bool> activateTask(String id) async {
    try {
      final activatedTask = await _taskRepository.activateTask(id);

      final index = tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        tasks[index] = activatedTask;
      }

      if (selectedTask?.id == id) {
        selectedTask = activatedTask;
      }

      return true;
    } catch (e) {
      error = e.toString();
      return false;
    }
  }

  @action
  Future<void> loadTags() async {
    try {
      final fetchedTags = await _taskRepository.getTags();
      tags.clear();
      tags.addAll(fetchedTags);
    } catch (e) {
      // Silently fail for tags
    }
  }

  @action
  void setFilter({TaskStatus? status, int? priority}) {
    filterStatus = status;
    filterPriority = priority;
  }

  @action
  void clearFilter() {
    filterStatus = null;
    filterPriority = null;
  }

  @action
  void clearError() {
    error = null;
  }

  @action
  void clearSelectedTask() {
    selectedTask = null;
  }
}
