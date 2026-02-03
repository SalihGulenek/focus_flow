import 'package:json_annotation/json_annotation.dart';

part 'focus_session_model.g.dart';

enum SessionStatus {
  @JsonValue('RUNNING')
  running,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('CANCELLED')
  cancelled,
  @JsonValue('PAUSED')
  paused,
}

@JsonSerializable()
class FocusSessionModel {
  @JsonKey(name: 'ID')
  final String id;
  @JsonKey(name: 'TaskID')
  final String? taskId;
  @JsonKey(name: 'TaskTitle')
  final String? taskTitle;
  @JsonKey(name: 'UserID')
  final String userId;
  @JsonKey(name: 'Duration')
  final int duration; // minutes
  @JsonKey(name: 'Status')
  final SessionStatus status;
  @JsonKey(name: 'StartedAt')
  final DateTime startedAt;
  @JsonKey(name: 'CompletedAt')
  final DateTime? completedAt;
  @JsonKey(name: 'PausedAt')
  final DateTime? pausedAt;
  @JsonKey(name: 'TotalPaused')
  final int totalPaused; // seconds
  @JsonKey(name: 'CreatedAt')
  final DateTime createdAt;

  FocusSessionModel({
    required this.id,
    this.taskId,
    this.taskTitle,
    required this.userId,
    required this.duration,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.pausedAt,
    required this.totalPaused,
    required this.createdAt,
  });

  // Computed properties
  bool get isRunning => status == SessionStatus.running;
  bool get isPaused => status == SessionStatus.paused;
  bool get isCompleted => status == SessionStatus.completed;
  bool get isCancelled => status == SessionStatus.cancelled;
  bool get isActive => isRunning || isPaused;

  int get totalDurationSeconds => duration * 60;

  int get elapsedSeconds {
    if (completedAt != null) {
      return completedAt!.difference(startedAt).inSeconds - totalPaused;
    }
    if (isPaused && pausedAt != null) {
      return pausedAt!.difference(startedAt).inSeconds - totalPaused;
    }
    return DateTime.now().difference(startedAt).inSeconds - totalPaused;
  }

  int get remainingSeconds {
    final remaining = totalDurationSeconds - elapsedSeconds;
    return remaining.clamp(0, totalDurationSeconds);
  }

  double get progress {
    if (isCompleted) return 1.0;
    if (totalDurationSeconds == 0) return 0.0;
    return (elapsedSeconds / totalDurationSeconds).clamp(0.0, 1.0);
  }

  int get actualDurationMinutes {
    final pausedMinutes = totalPaused ~/ 60;
    return (duration - pausedMinutes).clamp(0, duration);
  }

  String get formattedRemainingTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  factory FocusSessionModel.fromJson(Map<String, dynamic> json) => _$FocusSessionModelFromJson(json);
  Map<String, dynamic> toJson() => _$FocusSessionModelToJson(this);

  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'duration': duration,
      'status': status.name.toUpperCase(),
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'paused_at': pausedAt?.toIso8601String(),
      'total_paused': totalPaused,
      'created_at': createdAt.toIso8601String(),
      'synced': 0,
    };
  }

  factory FocusSessionModel.fromDb(Map<String, dynamic> map) {
    return FocusSessionModel(
      id: map['id'] as String,
      taskId: map['task_id'] as String?,
      taskTitle: null,
      userId: map['user_id'] as String,
      duration: map['duration'] as int,
      status: SessionStatus.values.firstWhere((s) => s.name.toUpperCase() == map['status'], orElse: () => SessionStatus.running),
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      pausedAt: map['paused_at'] != null ? DateTime.parse(map['paused_at'] as String) : null,
      totalPaused: map['total_paused'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  FocusSessionModel copyWith({
    String? id,
    String? taskId,
    String? taskTitle,
    String? userId,
    int? duration,
    SessionStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? pausedAt,
    int? totalPaused,
    DateTime? createdAt,
  }) {
    return FocusSessionModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      userId: userId ?? this.userId,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      totalPaused: totalPaused ?? this.totalPaused,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
