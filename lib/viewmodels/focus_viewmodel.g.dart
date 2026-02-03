// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_viewmodel.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$FocusViewModel on _FocusViewModelBase, Store {
  Computed<bool>? _$hasActiveSessionComputed;

  @override
  bool get hasActiveSession => (_$hasActiveSessionComputed ??= Computed<bool>(
    () => super.hasActiveSession,
    name: '_FocusViewModelBase.hasActiveSession',
  )).value;
  Computed<bool>? _$isRunningComputed;

  @override
  bool get isRunning => (_$isRunningComputed ??= Computed<bool>(
    () => super.isRunning,
    name: '_FocusViewModelBase.isRunning',
  )).value;
  Computed<bool>? _$isPausedComputed;

  @override
  bool get isPaused => (_$isPausedComputed ??= Computed<bool>(
    () => super.isPaused,
    name: '_FocusViewModelBase.isPaused',
  )).value;
  Computed<double>? _$progressComputed;

  @override
  double get progress => (_$progressComputed ??= Computed<double>(
    () => super.progress,
    name: '_FocusViewModelBase.progress',
  )).value;
  Computed<String>? _$formattedTimeComputed;

  @override
  String get formattedTime => (_$formattedTimeComputed ??= Computed<String>(
    () => super.formattedTime,
    name: '_FocusViewModelBase.formattedTime',
  )).value;
  Computed<int>? _$weeklyFocusMinutesComputed;

  @override
  int get weeklyFocusMinutes => (_$weeklyFocusMinutesComputed ??= Computed<int>(
    () => super.weeklyFocusMinutes,
    name: '_FocusViewModelBase.weeklyFocusMinutes',
  )).value;
  Computed<int>? _$todaySessionsComputed;

  @override
  int get todaySessions => (_$todaySessionsComputed ??= Computed<int>(
    () => super.todaySessions,
    name: '_FocusViewModelBase.todaySessions',
  )).value;
  Computed<int>? _$todayMinutesComputed;

  @override
  int get todayMinutes => (_$todayMinutesComputed ??= Computed<int>(
    () => super.todayMinutes,
    name: '_FocusViewModelBase.todayMinutes',
  )).value;

  late final _$activeSessionAtom = Atom(
    name: '_FocusViewModelBase.activeSession',
    context: context,
  );

  @override
  FocusSessionModel? get activeSession {
    _$activeSessionAtom.reportRead();
    return super.activeSession;
  }

  @override
  set activeSession(FocusSessionModel? value) {
    _$activeSessionAtom.reportWrite(value, super.activeSession, () {
      super.activeSession = value;
    });
  }

  late final _$sessionsAtom = Atom(
    name: '_FocusViewModelBase.sessions',
    context: context,
  );

  @override
  ObservableList<FocusSessionModel> get sessions {
    _$sessionsAtom.reportRead();
    return super.sessions;
  }

  @override
  set sessions(ObservableList<FocusSessionModel> value) {
    _$sessionsAtom.reportWrite(value, super.sessions, () {
      super.sessions = value;
    });
  }

  late final _$remainingSecondsAtom = Atom(
    name: '_FocusViewModelBase.remainingSeconds',
    context: context,
  );

  @override
  int get remainingSeconds {
    _$remainingSecondsAtom.reportRead();
    return super.remainingSeconds;
  }

  @override
  set remainingSeconds(int value) {
    _$remainingSecondsAtom.reportWrite(value, super.remainingSeconds, () {
      super.remainingSeconds = value;
    });
  }

  late final _$isLoadingAtom = Atom(
    name: '_FocusViewModelBase.isLoading',
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
    name: '_FocusViewModelBase.error',
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

  late final _$statsAtom = Atom(
    name: '_FocusViewModelBase.stats',
    context: context,
  );

  @override
  Map<String, dynamic> get stats {
    _$statsAtom.reportRead();
    return super.stats;
  }

  @override
  set stats(Map<String, dynamic> value) {
    _$statsAtom.reportWrite(value, super.stats, () {
      super.stats = value;
    });
  }

  late final _$loadActiveSessionAsyncAction = AsyncAction(
    '_FocusViewModelBase.loadActiveSession',
    context: context,
  );

  @override
  Future<void> loadActiveSession(String userId) {
    return _$loadActiveSessionAsyncAction.run(
      () => super.loadActiveSession(userId),
    );
  }

  late final _$startSessionAsyncAction = AsyncAction(
    '_FocusViewModelBase.startSession',
    context: context,
  );

  @override
  Future<bool> startSession({
    required String userId,
    String? taskId,
    required int duration,
  }) {
    return _$startSessionAsyncAction.run(
      () => super.startSession(
        userId: userId,
        taskId: taskId,
        duration: duration,
      ),
    );
  }

  late final _$pauseSessionAsyncAction = AsyncAction(
    '_FocusViewModelBase.pauseSession',
    context: context,
  );

  @override
  Future<bool> pauseSession() {
    return _$pauseSessionAsyncAction.run(() => super.pauseSession());
  }

  late final _$resumeSessionAsyncAction = AsyncAction(
    '_FocusViewModelBase.resumeSession',
    context: context,
  );

  @override
  Future<bool> resumeSession() {
    return _$resumeSessionAsyncAction.run(() => super.resumeSession());
  }

  late final _$completeSessionAsyncAction = AsyncAction(
    '_FocusViewModelBase.completeSession',
    context: context,
  );

  @override
  Future<bool> completeSession() {
    return _$completeSessionAsyncAction.run(() => super.completeSession());
  }

  late final _$cancelSessionAsyncAction = AsyncAction(
    '_FocusViewModelBase.cancelSession',
    context: context,
  );

  @override
  Future<bool> cancelSession() {
    return _$cancelSessionAsyncAction.run(() => super.cancelSession());
  }

  late final _$loadSessionsAsyncAction = AsyncAction(
    '_FocusViewModelBase.loadSessions',
    context: context,
  );

  @override
  Future<void> loadSessions({SessionStatus? status}) {
    return _$loadSessionsAsyncAction.run(
      () => super.loadSessions(status: status),
    );
  }

  late final _$loadStatsAsyncAction = AsyncAction(
    '_FocusViewModelBase.loadStats',
    context: context,
  );

  @override
  Future<void> loadStats() {
    return _$loadStatsAsyncAction.run(() => super.loadStats());
  }

  late final _$_FocusViewModelBaseActionController = ActionController(
    name: '_FocusViewModelBase',
    context: context,
  );

  @override
  void clearError() {
    final _$actionInfo = _$_FocusViewModelBaseActionController.startAction(
      name: '_FocusViewModelBase.clearError',
    );
    try {
      return super.clearError();
    } finally {
      _$_FocusViewModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
activeSession: ${activeSession},
sessions: ${sessions},
remainingSeconds: ${remainingSeconds},
isLoading: ${isLoading},
error: ${error},
stats: ${stats},
hasActiveSession: ${hasActiveSession},
isRunning: ${isRunning},
isPaused: ${isPaused},
progress: ${progress},
formattedTime: ${formattedTime},
weeklyFocusMinutes: ${weeklyFocusMinutes},
todaySessions: ${todaySessions},
todayMinutes: ${todayMinutes}
    ''';
  }
}
