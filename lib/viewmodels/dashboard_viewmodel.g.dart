// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_viewmodel.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$DashboardViewModel on _DashboardViewModelBase, Store {
  Computed<int>? _$remainingTasksComputed;

  @override
  int get remainingTasks => (_$remainingTasksComputed ??= Computed<int>(
    () => super.remainingTasks,
    name: '_DashboardViewModelBase.remainingTasks',
  )).value;
  Computed<double>? _$progressPercentComputed;

  @override
  double get progressPercent => (_$progressPercentComputed ??= Computed<double>(
    () => super.progressPercent,
    name: '_DashboardViewModelBase.progressPercent',
  )).value;
  Computed<String>? _$greetingComputed;

  @override
  String get greeting => (_$greetingComputed ??= Computed<String>(
    () => super.greeting,
    name: '_DashboardViewModelBase.greeting',
  )).value;
  Computed<String>? _$formattedDateComputed;

  @override
  String get formattedDate => (_$formattedDateComputed ??= Computed<String>(
    () => super.formattedDate,
    name: '_DashboardViewModelBase.formattedDate',
  )).value;
  Computed<List<TaskModel>>? _$priorityTasksComputed;

  @override
  List<TaskModel> get priorityTasks =>
      (_$priorityTasksComputed ??= Computed<List<TaskModel>>(
        () => super.priorityTasks,
        name: '_DashboardViewModelBase.priorityTasks',
      )).value;
  Computed<List<TaskModel>>? _$completedTasksListComputed;

  @override
  List<TaskModel> get completedTasksList =>
      (_$completedTasksListComputed ??= Computed<List<TaskModel>>(
        () => super.completedTasksList,
        name: '_DashboardViewModelBase.completedTasksList',
      )).value;

  late final _$isLoadingAtom = Atom(
    name: '_DashboardViewModelBase.isLoading',
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
    name: '_DashboardViewModelBase.error',
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

  late final _$todayTasksAtom = Atom(
    name: '_DashboardViewModelBase.todayTasks',
    context: context,
  );

  @override
  ObservableList<TaskModel> get todayTasks {
    _$todayTasksAtom.reportRead();
    return super.todayTasks;
  }

  @override
  set todayTasks(ObservableList<TaskModel> value) {
    _$todayTasksAtom.reportWrite(value, super.todayTasks, () {
      super.todayTasks = value;
    });
  }

  late final _$totalTasksAtom = Atom(
    name: '_DashboardViewModelBase.totalTasks',
    context: context,
  );

  @override
  int get totalTasks {
    _$totalTasksAtom.reportRead();
    return super.totalTasks;
  }

  @override
  set totalTasks(int value) {
    _$totalTasksAtom.reportWrite(value, super.totalTasks, () {
      super.totalTasks = value;
    });
  }

  late final _$completedTasksAtom = Atom(
    name: '_DashboardViewModelBase.completedTasks',
    context: context,
  );

  @override
  int get completedTasks {
    _$completedTasksAtom.reportRead();
    return super.completedTasks;
  }

  @override
  set completedTasks(int value) {
    _$completedTasksAtom.reportWrite(value, super.completedTasks, () {
      super.completedTasks = value;
    });
  }

  late final _$weeklyFocusMinutesAtom = Atom(
    name: '_DashboardViewModelBase.weeklyFocusMinutes',
    context: context,
  );

  @override
  int get weeklyFocusMinutes {
    _$weeklyFocusMinutesAtom.reportRead();
    return super.weeklyFocusMinutes;
  }

  @override
  set weeklyFocusMinutes(int value) {
    _$weeklyFocusMinutesAtom.reportWrite(value, super.weeklyFocusMinutes, () {
      super.weeklyFocusMinutes = value;
    });
  }

  late final _$activeTaskAtom = Atom(
    name: '_DashboardViewModelBase.activeTask',
    context: context,
  );

  @override
  TaskModel? get activeTask {
    _$activeTaskAtom.reportRead();
    return super.activeTask;
  }

  @override
  set activeTask(TaskModel? value) {
    _$activeTaskAtom.reportWrite(value, super.activeTask, () {
      super.activeTask = value;
    });
  }

  late final _$loadDashboardAsyncAction = AsyncAction(
    '_DashboardViewModelBase.loadDashboard',
    context: context,
  );

  @override
  Future<void> loadDashboard(String userId) {
    return _$loadDashboardAsyncAction.run(() => super.loadDashboard(userId));
  }

  late final _$refreshDashboardAsyncAction = AsyncAction(
    '_DashboardViewModelBase.refreshDashboard',
    context: context,
  );

  @override
  Future<void> refreshDashboard(String userId) {
    return _$refreshDashboardAsyncAction.run(
      () => super.refreshDashboard(userId),
    );
  }

  late final _$completeTaskAsyncAction = AsyncAction(
    '_DashboardViewModelBase.completeTask',
    context: context,
  );

  @override
  Future<bool> completeTask(String taskId) {
    return _$completeTaskAsyncAction.run(() => super.completeTask(taskId));
  }

  late final _$_DashboardViewModelBaseActionController = ActionController(
    name: '_DashboardViewModelBase',
    context: context,
  );

  @override
  void clearError() {
    final _$actionInfo = _$_DashboardViewModelBaseActionController.startAction(
      name: '_DashboardViewModelBase.clearError',
    );
    try {
      return super.clearError();
    } finally {
      _$_DashboardViewModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
error: ${error},
todayTasks: ${todayTasks},
totalTasks: ${totalTasks},
completedTasks: ${completedTasks},
weeklyFocusMinutes: ${weeklyFocusMinutes},
activeTask: ${activeTask},
remainingTasks: ${remainingTasks},
progressPercent: ${progressPercent},
greeting: ${greeting},
formattedDate: ${formattedDate},
priorityTasks: ${priorityTasks},
completedTasksList: ${completedTasksList}
    ''';
  }
}
