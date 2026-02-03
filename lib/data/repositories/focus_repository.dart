import 'package:uuid/uuid.dart';
import '../../services/api_service.dart';
import '../../services/database_service.dart';
import '../models/focus_session_model.dart';

class FocusRepository {
  final ApiService _apiService;
  final DatabaseService _databaseService;
  final _uuid = const Uuid();

  FocusRepository(this._apiService, this._databaseService);

  // Remote operations
  Future<FocusSessionModel> startSession({
    required String userId,
    String? taskId,
    required int duration,
  }) async {
    final now = DateTime.now();
    final localId = _uuid.v4();

    // Create local session first
    final localSession = FocusSessionModel(
      id: localId,
      taskId: taskId,
      userId: userId,
      duration: duration,
      status: SessionStatus.running,
      startedAt: now,
      totalPaused: 0,
      createdAt: now,
    );

    await _cacheSession(localSession);

    try {
      final response = await _apiService.createFocusSession(taskId, duration);
      final serverSession = FocusSessionModel.fromJson(response.data);

      // Update local cache with server ID
      await _databaseService.delete('focus_sessions', where: 'id = ?', whereArgs: [localId]);
      await _cacheSession(serverSession);

      return serverSession;
    } catch (_) {
      return localSession;
    }
  }

  Future<FocusSessionModel> completeSession(String id) async {
    final session = await getLocalSession(id);
    if (session == null) throw Exception('Session not found');

    final completedSession = session.copyWith(
      status: SessionStatus.completed,
      completedAt: DateTime.now(),
    );

    await _cacheSession(completedSession);

    try {
      final response = await _apiService.completeFocusSession(id);
      final serverSession = FocusSessionModel.fromJson(response.data);
      await _cacheSession(serverSession);
      return serverSession;
    } catch (_) {
      return completedSession;
    }
  }

  Future<FocusSessionModel> pauseSession(String id) async {
    final session = await getLocalSession(id);
    if (session == null) throw Exception('Session not found');

    final pausedSession = session.copyWith(
      status: SessionStatus.paused,
      pausedAt: DateTime.now(),
    );

    await _cacheSession(pausedSession);

    try {
      final response = await _apiService.pauseFocusSession(id);
      final serverSession = FocusSessionModel.fromJson(response.data);
      await _cacheSession(serverSession);
      return serverSession;
    } catch (_) {
      return pausedSession;
    }
  }

  Future<FocusSessionModel> resumeSession(String id) async {
    final session = await getLocalSession(id);
    if (session == null) throw Exception('Session not found');

    // Calculate additional paused time
    int additionalPaused = 0;
    if (session.pausedAt != null) {
      additionalPaused = DateTime.now().difference(session.pausedAt!).inSeconds;
    }

    final resumedSession = session.copyWith(
      status: SessionStatus.running,
      pausedAt: null,
      totalPaused: session.totalPaused + additionalPaused,
    );

    await _cacheSession(resumedSession);

    try {
      final response = await _apiService.resumeFocusSession(id);
      final serverSession = FocusSessionModel.fromJson(response.data);
      await _cacheSession(serverSession);
      return serverSession;
    } catch (_) {
      return resumedSession;
    }
  }

  Future<FocusSessionModel> cancelSession(String id) async {
    final session = await getLocalSession(id);
    if (session == null) throw Exception('Session not found');

    final cancelledSession = session.copyWith(
      status: SessionStatus.cancelled,
      completedAt: DateTime.now(),
    );

    await _cacheSession(cancelledSession);

    return cancelledSession;
  }

  Future<List<FocusSessionModel>> fetchSessions({SessionStatus? status}) async {
    try {
      final response = await _apiService.getFocusSessions(
        status: status?.name.toUpperCase(),
      );

      final sessionsData = response.data['sessions'] as List;
      final sessions = sessionsData
          .map((json) => FocusSessionModel.fromJson(json))
          .toList();

      for (final session in sessions) {
        await _cacheSession(session);
      }

      return sessions;
    } catch (_) {
      return await getLocalSessions(status: status);
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _apiService.getFocusStats();
      return response.data;
    } catch (_) {
      return await getLocalStats();
    }
  }

  // Local operations
  Future<FocusSessionModel?> getActiveSession(String userId) async {
    final results = await _databaseService.query(
      'focus_sessions',
      where: 'user_id = ? AND (status = ? OR status = ?)',
      whereArgs: [userId, 'RUNNING', 'PAUSED'],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return FocusSessionModel.fromDb(results.first);
  }

  Future<FocusSessionModel?> getLocalSession(String id) async {
    final results = await _databaseService.query(
      'focus_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return FocusSessionModel.fromDb(results.first);
  }

  Future<List<FocusSessionModel>> getLocalSessions({
    SessionStatus? status,
    int limit = 50,
  }) async {
    String? where;
    List<dynamic>? whereArgs;

    if (status != null) {
      where = 'status = ?';
      whereArgs = [status.name.toUpperCase()];
    }

    final results = await _databaseService.query(
      'focus_sessions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'started_at DESC',
      limit: limit,
    );

    return results.map((map) => FocusSessionModel.fromDb(map)).toList();
  }

  Future<Map<String, dynamic>> getLocalStats() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    // Weekly focus minutes
    final weeklyResults = await _databaseService.rawQuery('''
      SELECT SUM(duration - (total_paused / 60)) as total_minutes
      FROM focus_sessions
      WHERE status = 'COMPLETED' AND started_at >= ?
    ''', [startOfWeekDate.toIso8601String()]);

    final weeklyMinutes = weeklyResults.first['total_minutes'] as int? ?? 0;

    // Total sessions
    final totalResults = await _databaseService.rawQuery('''
      SELECT COUNT(*) as count FROM focus_sessions WHERE status = 'COMPLETED'
    ''');

    final totalSessions = totalResults.first['count'] as int? ?? 0;

    // Today's sessions
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final todayResults = await _databaseService.rawQuery('''
      SELECT COUNT(*) as count, SUM(duration - (total_paused / 60)) as minutes
      FROM focus_sessions
      WHERE status = 'COMPLETED' AND started_at >= ?
    ''', [startOfDay.toIso8601String()]);

    final todaySessions = todayResults.first['count'] as int? ?? 0;
    final todayMinutes = todayResults.first['minutes'] as int? ?? 0;

    return {
      'weekly_focus_minutes': weeklyMinutes,
      'total_sessions': totalSessions,
      'today_sessions': todaySessions,
      'today_minutes': todayMinutes,
    };
  }

  Future<void> _cacheSession(FocusSessionModel session) async {
    await _databaseService.insert('focus_sessions', session.toDb());
  }
}
