// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_viewmodel.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$TaskViewModel on _TaskViewModelBase, Store {
  Computed<List<TaskModel>>? _$filteredTasksComputed;

  @override
  List<TaskModel> get filteredTasks =>
      (_$filteredTasksComputed ??= Computed<List<TaskModel>>(
        () => super.filteredTasks,
        name: '_TaskViewModelBase.filteredTasks',
      )).value;
  Computed<List<TaskModel>>? _$pendingTasksComputed;

  @override
  List<TaskModel> get pendingTasks =>
      (_$pendingTasksComputed ??= Computed<List<TaskModel>>(
        () => super.pendingTasks,
        name: '_TaskViewModelBase.pendingTasks',
      )).value;
  Computed<List<TaskModel>>? _$activeTasksComputed;

  @override
  List<TaskModel> get activeTasks =>
      (_$activeTasksComputed ??= Computed<List<TaskModel>>(
        () => super.activeTasks,
        name: '_TaskViewModelBase.activeTasks',
      )).value;
  Computed<List<TaskModel>>? _$blockedTasksComputed;

  @override
  List<TaskModel> get blockedTasks =>
      (_$blockedTasksComputed ??= Computed<List<TaskModel>>(
        () => super.blockedTasks,
        name: '_TaskViewModelBase.blockedTasks',
      )).value;
  Computed<List<TaskModel>>? _$completedTasksComputed;

  @override
  List<TaskModel> get completedTasks =>
      (_$completedTasksComputed ??= Computed<List<TaskModel>>(
        () => super.completedTasks,
        name: '_TaskViewModelBase.completedTasks',
      )).value;
  Computed<int>? _$totalTasksComputed;

  @override
  int get totalTasks => (_$totalTasksComputed ??= Computed<int>(
    () => super.totalTasks,
    name: '_TaskViewModelBase.totalTasks',
  )).value;
  Computed<int>? _$completedCountComputed;

  @override
  int get completedCount => (_$completedCountComputed ??= Computed<int>(
    () => super.completedCount,
    name: '_TaskViewModelBase.completedCount',
  )).value;
  Computed<double>? _$progressPercentComputed;

  @override
  double get progressPercent => (_$progressPercentComputed ??= Computed<double>(
    () => super.progressPercent,
    name: '_TaskViewModelBase.progressPercent',
  )).value;

  late final _$tasksAtom = Atom(
    name: '_TaskViewModelBase.tasks',
    context: context,
  );

  @override
  ObservableList<TaskModel> get tasks {
    _$tasksAtom.reportRead();
    return super.tasks;
  }

  @override
  set tasks(ObservableList<TaskModel> value) {
    _$tasksAtom.reportWrite(value, super.tasks, () {
      super.tasks = value;
    });
  }

  late final _$selectedTaskAtom = Atom(
    name: '_TaskViewModelBase.selectedTask',
    context: context,
  );

  @override
  TaskModel? get selectedTask {
    _$selectedTaskAtom.reportRead();
    return super.selectedTask;
  }

  @override
  set selectedTask(TaskModel? value) {
    _$selectedTaskAtom.reportWrite(value, super.selectedTask, () {
      super.selectedTask = value;
    });
  }

  late final _$tagsAtom = Atom(
    name: '_TaskViewModelBase.tags',
    context: context,
  );

  @override
  ObservableList<TagModel> get tags {
    _$tagsAtom.reportRead();
    return super.tags;
  }

  @override
  set tags(ObservableList<TagModel> value) {
    _$tagsAtom.reportWrite(value, super.tags, () {
      super.tags = value;
    });
  }

  late final _$isLoadingAtom = Atom(
    name: '_TaskViewModelBase.isLoading',
    context: context,
  );

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$errorAtom = Atom(
    name: '_TaskViewModelBase.error',
    context: context,
  );

  @override
  String? get error {
    _$errorAtom.reportRead();
    return super.error;
  }

  @override
  set error(String? value) {
    _$errorAtom.reportWrite(value, super.error, () {
      super.error = value;
    });
  }

  late final _$filterStatusAtom = Atom(
    name: '_TaskViewModelBase.filterStatus',
    context: context,
  );

  @override
  TaskStatus? get filterStatus {
    _$filterStatusAtom.reportRead();
    return super.filterStatus;
  }

  @override
  set filterStatus(TaskStatus? value) {
    _$filterStatusAtom.reportWrite(value, super.filterStatus, () {
      super.filterStatus = value;
    });
  }

  late final _$filterPriorityAtom = Atom(
    name: '_TaskViewModelBase.filterPriority',
    context: context,
  );

  @override
  int? get filterPriority {
    _$filterPriorityAtom.reportRead();
    return super.filterPriority;
  }

  @override
  set filterPriority(int? value) {
    _$filterPriorityAtom.reportWrite(value, super.filterPriority, () {
      super.filterPriority = value;
    });
  }

  late final _$loadTasksAsyncAction = AsyncAction(
    '_TaskViewModelBase.loadTasks',
    context: context,
  );

  @override
  Future<void> loadTasks({bool refresh = false}) {
    return _$loadTasksAsyncAction.run(() => super.loadTasks(refresh: refresh));
  }

  late final _$loadLocalTasksAsyncAction = AsyncAction(
    '_TaskViewModelBase.loadLocalTasks',
    context: context,
  );

  @override
  Future<void> loadLocalTasks() {
    return _$loadLocalTasksAsyncAction.run(() => super.loadLocalTasks());
  }

  late final _$loadTaskAsyncAction = AsyncAction(
    '_TaskViewModelBase.loadTask',
    context: context,
  );

  @override
  Future<void> loadTask(String id) {
    return _$loadTaskAsyncAction.run(() => super.loadTask(id));
  }

  late final _$createTaskAsyncAction = AsyncAction(
    '_TaskViewModelBase.createTask',
    context: context,
  );

  @override
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
  }) {
    return _$createTaskAsyncAction.run(
      () => super.createTask(
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
      ),
    );
  }

  late final _$updateTaskAsyncAction = AsyncAction(
    '_TaskViewModelBase.updateTask',
    context: context,
  );

  @override
  Future<bool> updateTask(
    String id, {
    String? title,
    String? description,
    TaskStatus? status,
    int? priority,
    DateTime? dueDate,
    bool? isRecurring,
    String? recurrenceRule,
    DateTime? recurrenceEnd,
  }) {
    return _$updateTaskAsyncAction.run(
      () => super.updateTask(
        id,
        title: title,
        description: description,
        status: status,
        priority: priority,
        dueDate: dueDate,
        isRecurring: isRecurring,
        recurrenceRule: recurrenceRule,
        recurrenceEnd: recurrenceEnd,
      ),
    );
  }

  late final _$deleteTaskAsyncAction = AsyncAction(
    '_TaskViewModelBase.deleteTask',
    context: context,
  );

  @override
  Future<bool> deleteTask(String id) {
    return _$deleteTaskAsyncAction.run(() => super.deleteTask(id));
  }

  late final _$completeTaskAsyncAction = AsyncAction(
    '_TaskViewModelBase.completeTask',
    context: context,
  );

  @override
  Future<bool> completeTask(String id) {
    return _$completeTaskAsyncAction.run(() => super.completeTask(id));
  }

  late final _$activateTaskAsyncAction = AsyncAction(
    '_TaskViewModelBase.activateTask',
    context: context,
  );

  @override
  Future<bool> activateTask(String id) {
    return _$activateTaskAsyncAction.run(() => super.activateTask(id));
  }

  late final _$loadTagsAsyncAction = AsyncAction(
    '_TaskViewModelBase.loadTags',
    context: context,
  );

  @override
  Future<void> loadTags() {
    return _$loadTagsAsyncAction.run(() => super.loadTags());
  }

  late final _$_TaskViewModelBaseActionController = ActionController(
    name: '_TaskViewModelBase',
    context: context,
  );

  @override
  void setFilter({TaskStatus? status, int? priority}) {
    final _$actionInfo = _$_TaskViewModelBaseActionController.startAction(
      name: '_TaskViewModelBase.setFilter',
    );
    try {
      return super.setFilter(status: status, priority: priority);
    } finally {
      _$_TaskViewModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearFilter() {
    final _$actionInfo = _$_TaskViewModelBaseActionController.startAction(
      name: '_TaskViewModelBase.clearFilter',
    );
    try {
      return super.clearFilter();
    } finally {
      _$_TaskViewModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearError() {
    final _$actionInfo = _$_TaskViewModelBaseActionController.startAction(
      name: '_TaskViewModelBase.clearError',
    );
    try {
      return super.clearError();
    } finally {
      _$_TaskViewModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearSelectedTask() {
    final _$actionInfo = _$_TaskViewModelBaseActionController.startAction(
      name: '_TaskViewModelBase.clearSelectedTask',
    );
    try {
      return super.clearSelectedTask();
    } finally {
      _$_TaskViewModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
tasks: ${tasks},
selectedTask: ${selectedTask},
tags: ${tags},
isLoading: ${isLoading},
error: ${error},
filterStatus: ${filterStatus},
filterPriority: ${filterPriority},
filteredTasks: ${filteredTasks},
pendingTasks: ${pendingTasks},
activeTasks: ${activeTasks},
blockedTasks: ${blockedTasks},
completedTasks: ${completedTasks},
totalTasks: ${totalTasks},
completedCount: ${completedCount},
progressPercent: ${progressPercent}
    ''';
  }
}
