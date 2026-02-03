import 'dart:async';
import 'package:mobx/mobx.dart';
import '../data/repositories/focus_repository.dart';
import '../data/models/focus_session_model.dart';

part 'focus_viewmodel.g.dart';

class FocusViewModel = _FocusViewModelBase with _$FocusViewModel;

abstract class _FocusViewModelBase with Store {
  final FocusRepository _focusRepository;
  Timer? _timer;

  _FocusViewModelBase(this._focusRepository);

  @observable
  FocusSessionModel? activeSession;

  @observable
  ObservableList<FocusSessionModel> sessions = ObservableList<FocusSessionModel>();

  @observable
  int remainingSeconds = 0;

  @observable
  bool isLoading = false;

  @observable
  String? error;

  @observable
  Map<String, dynamic> stats = {};

  @computed
  bool get hasActiveSession => activeSession != null && activeSession!.isActive;

  @computed
  bool get isRunning => activeSession?.isRunning ?? false;

  @computed
  bool get isPaused => activeSession?.isPaused ?? false;

  @computed
  double get progress {
    if (activeSession == null) return 0.0;
    final total = activeSession!.totalDurationSeconds;
    if (total == 0) return 0.0;
    final elapsed = total - remainingSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  @computed
  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @computed
  int get weeklyFocusMinutes => stats['weekly_focus_minutes'] as int? ?? 0;

  @computed
  int get todaySessions => stats['today_sessions'] as int? ?? 0;

  @computed
  int get todayMinutes => stats['today_minutes'] as int? ?? 0;

  @action
  Future<void> loadActiveSession(String userId) async {
    isLoading = true;
    error = null;

    try {
      activeSession = await _focusRepository.getActiveSession(userId);
      if (activeSession != null) {
        remainingSeconds = activeSession!.remainingSeconds;
        if (activeSession!.isRunning) {
          _startTimer();
        }
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<bool> startSession({
    required String userId,
    String? taskId,
    required int duration,
  }) async {
    if (hasActiveSession) {
      error = 'You already have an active session';
      return false;
    }

    isLoading = true;
    error = null;

    try {
      activeSession = await _focusRepository.startSession(
        userId: userId,
        taskId: taskId,
        duration: duration,
      );

      remainingSeconds = duration * 60;
      _startTimer();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<bool> pauseSession() async {
    if (activeSession == null || !activeSession!.isRunning) {
      error = 'No running session to pause';
      return false;
    }

    try {
      _stopTimer();
      activeSession = await _focusRepository.pauseSession(activeSession!.id);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    }
  }

  @action
  Future<bool> resumeSession() async {
    if (activeSession == null || !activeSession!.isPaused) {
      error = 'No paused session to resume';
      return false;
    }

    try {
      activeSession = await _focusRepository.resumeSession(activeSession!.id);
      _startTimer();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    }
  }

  @action
  Future<bool> completeSession() async {
    if (activeSession == null) {
      error = 'No session to complete';
      return false;
    }

    try {
      _stopTimer();
      final completedSession = await _focusRepository.completeSession(activeSession!.id);
      sessions.insert(0, completedSession);
      activeSession = null;
      remainingSeconds = 0;
      await loadStats();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    }
  }

  @action
  Future<bool> cancelSession() async {
    if (activeSession == null) {
      error = 'No session to cancel';
      return false;
    }

    try {
      _stopTimer();
      await _focusRepository.cancelSession(activeSession!.id);
      activeSession = null;
      remainingSeconds = 0;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    }
  }

  @action
  Future<void> loadSessions({SessionStatus? status}) async {
    isLoading = true;
    error = null;

    try {
      final fetchedSessions = await _focusRepository.fetchSessions(status: status);
      sessions.clear();
      sessions.addAll(fetchedSessions);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> loadStats() async {
    try {
      stats = await _focusRepository.getStats();
    } catch (e) {
      // Silently fail
    }
  }

  @action
  void clearError() {
    error = null;
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds > 0) {
        remainingSeconds--;
      } else {
        _onTimerComplete();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _onTimerComplete() {
    _stopTimer();
    completeSession();
  }

  void dispose() {
    _stopTimer();
  }
}
