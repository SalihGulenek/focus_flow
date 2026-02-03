import 'package:uuid/uuid.dart';
import '../../services/api_service.dart';
import '../../services/database_service.dart';
import '../models/task_model.dart';
import '../models/tag_model.dart';

class TaskRepository {
  final ApiService _apiService;
  final DatabaseService _databaseService;
  final _uuid = const Uuid();

  TaskRepository(this._apiService, this._databaseService);

  // Remote operations
  Future<List<TaskModel>> fetchTasks({int page = 1, int limit = 20, TaskStatus? status, int? priority}) async {
    try {
      final response = await _apiService.getTasks(page: page, limit: limit, status: status?.name.toUpperCase(), priority: priority);

      final tasksData = response.data['tasks'] as List;
      final tasks = tasksData.map((json) => TaskModel.fromJson(json)).toList();

      // Cache tasks locally
      for (final task in tasks) {
        await _cacheTask(task);
      }

      return tasks;
    } catch (_) {
      // Fallback to local cache
      return await getLocalTasks(status: status, priority: priority);
    }
  }

  Future<TaskModel> fetchTask(String id) async {
    try {
      final response = await _apiService.getTask(id);
      final task = TaskModel.fromJson(response.data);
      await _cacheTask(task);
      return task;
    } catch (_) {
      // Fallback to local cache
      final localTask = await getLocalTask(id);
      if (localTask != null) return localTask;
      rethrow;
    }
  }

  Future<TaskModel> createTask({
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
    final now = DateTime.now();
    final localId = _uuid.v4();

    // Create local task first
    final localTask = TaskModel(
      id: localId,
      userId: userId,
      title: title,
      description: description,
      status: TaskStatus.pending,
      priority: priority,
      dueDate: dueDate,
      isRecurring: isRecurring,
      recurrenceRule: recurrenceRule,
      recurrenceEnd: recurrenceEnd,
      parentId: parentId,
      createdAt: now,
      updatedAt: now,
    );

    await _cacheTask(localTask);

    try {
      // Sync with server
      final response = await _apiService.createTask({
        'title': title,
        'description': description,
        'priority': priority,
        'due_date': dueDate?.toIso8601String(),
        'is_recurring': isRecurring,
        'recurrence_rule': recurrenceRule,
        'recurrence_end': recurrenceEnd?.toIso8601String(),
        'parent_id': parentId,
        'tag_ids': tagIds,
        'blocker_task_ids': blockerTaskIds,
      });

      final serverTask = TaskModel.fromJson(response.data);

      // Update local cache with server ID
      await _databaseService.delete('tasks', where: 'id = ?', whereArgs: [localId]);
      await _cacheTask(serverTask);

      return serverTask;
    } catch (_) {
      // Keep local version for offline support
      return localTask;
    }
  }

  Future<TaskModel> updateTask(
    String id, {
    String? title,
    String? description,
    TaskStatus? status,
    int? priority,
    DateTime? dueDate,
    bool? isRecurring,
    String? recurrenceRule,
    DateTime? recurrenceEnd,
  }) async {
    final existingTask = await getLocalTask(id);
    if (existingTask == null) {
      throw Exception('Task not found');
    }

    final updatedTask = existingTask.copyWith(
      title: title,
      description: description,
      status: status,
      priority: priority,
      dueDate: dueDate,
      isRecurring: isRecurring,
      recurrenceRule: recurrenceRule,
      recurrenceEnd: recurrenceEnd,
      updatedAt: DateTime.now(),
    );

    await _cacheTask(updatedTask);

    try {
      final response = await _apiService.updateTask(id, {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (status != null) 'status': status.name.toUpperCase(),
        if (priority != null) 'priority': priority,
        if (dueDate != null) 'due_date': dueDate.toIso8601String(),
        if (isRecurring != null) 'is_recurring': isRecurring,
        if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
        if (recurrenceEnd != null) 'recurrence_end': recurrenceEnd.toIso8601String(),
      });

      final serverTask = TaskModel.fromJson(response.data);
      await _cacheTask(serverTask);
      return serverTask;
    } catch (_) {
      return updatedTask;
    }
  }

  Future<void> deleteTask(String id) async {
    await _databaseService.delete('tasks', where: 'id = ?', whereArgs: [id]);

    try {
      await _apiService.deleteTask(id);
    } catch (_) {
      // Task deleted locally, will sync later
    }
  }

  Future<TaskModel> completeTask(String id) async {
    final task = await getLocalTask(id);
    if (task == null) throw Exception('Task not found');

    final completedTask = task.copyWith(status: TaskStatus.completed, completedAt: DateTime.now(), updatedAt: DateTime.now());

    await _cacheTask(completedTask);

    try {
      final response = await _apiService.completeTask(id);
      final serverTask = TaskModel.fromJson(response.data);
      await _cacheTask(serverTask);
      return serverTask;
    } catch (_) {
      return completedTask;
    }
  }

  Future<TaskModel> activateTask(String id) async {
    final task = await getLocalTask(id);
    if (task == null) throw Exception('Task not found');

    final activatedTask = task.copyWith(status: TaskStatus.active, updatedAt: DateTime.now());

    await _cacheTask(activatedTask);

    try {
      final response = await _apiService.activateTask(id);
      final serverTask = TaskModel.fromJson(response.data);
      await _cacheTask(serverTask);
      return serverTask;
    } catch (_) {
      return activatedTask;
    }
  }

  // Subtasks
  Future<List<TaskModel>> getSubtasks(String parentId) async {
    try {
      final response = await _apiService.getSubtasks(parentId);
      final subtasksData = response.data as List;
      return subtasksData.map((json) => TaskModel.fromJson(json)).toList();
    } catch (_) {
      return await getLocalSubtasks(parentId);
    }
  }

  // Dependencies
  Future<void> addDependency(String taskId, String blockerTaskId) async {
    await _apiService.addDependency(taskId, blockerTaskId);
  }

  Future<void> removeDependency(String taskId, String blockerTaskId) async {
    await _apiService.removeDependency(taskId, blockerTaskId);
  }

  // Tags
  Future<List<TagModel>> getTags() async {
    try {
      final response = await _apiService.getTags();
      final tagsData = response.data as List;
      return tagsData.map((json) => TagModel.fromJson(json)).toList();
    } catch (_) {
      return await getLocalTags();
    }
  }

  // Local operations
  Future<List<TaskModel>> getLocalTasks({TaskStatus? status, int? priority, String? parentId}) async {
    String? where;
    List<dynamic>? whereArgs;

    final conditions = <String>[];
    final args = <dynamic>[];

    if (status != null) {
      conditions.add('status = ?');
      args.add(status.name.toUpperCase());
    }
    if (priority != null) {
      conditions.add('priority = ?');
      args.add(priority);
    }
    if (parentId != null) {
      conditions.add('parent_id = ?');
      args.add(parentId);
    } else {
      conditions.add('parent_id IS NULL');
    }

    if (conditions.isNotEmpty) {
      where = conditions.join(' AND ');
      whereArgs = args.isNotEmpty ? args : null;
    }

    final results = await _databaseService.query('tasks', where: where, whereArgs: whereArgs, orderBy: 'priority ASC, due_date ASC');

    return results.map((map) => TaskModel.fromDb(map)).toList();
  }

  Future<TaskModel?> getLocalTask(String id) async {
    final results = await _databaseService.query('tasks', where: 'id = ?', whereArgs: [id]);

    if (results.isEmpty) return null;
    return TaskModel.fromDb(results.first);
  }

  Future<List<TaskModel>> getLocalSubtasks(String parentId) async {
    final results = await _databaseService.query('tasks', where: 'parent_id = ?', whereArgs: [parentId], orderBy: 'created_at ASC');

    return results.map((map) => TaskModel.fromDb(map)).toList();
  }

  Future<List<TagModel>> getLocalTags() async {
    final results = await _databaseService.query('tags', orderBy: 'name ASC');
    return results.map((map) => TagModel.fromDb(map)).toList();
  }

  Future<void> _cacheTask(TaskModel task) async {
    await _databaseService.insert('tasks', task.toDb());
  }

  // Dashboard data
  Future<Map<String, dynamic>> getTodayStats(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final tasks = await _databaseService.rawQuery(
      '''
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN status = 'COMPLETED' THEN 1 ELSE 0 END) as completed
      FROM tasks
      WHERE user_id = ?
        AND (due_date BETWEEN ? AND ? OR (due_date IS NULL AND DATE(created_at) = DATE(?)))
    ''',
      [userId, startOfDay.toIso8601String(), endOfDay.toIso8601String(), startOfDay.toIso8601String()],
    );

    final result = tasks.first;
    final total = result['total'] as int? ?? 0;
    final completed = result['completed'] as int? ?? 0;

    return {'total': total, 'completed': completed, 'remaining': total - completed, 'progress': total > 0 ? (completed / total) : 0.0};
  }
}
