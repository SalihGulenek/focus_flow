// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FocusSessionModel _$FocusSessionModelFromJson(Map<String, dynamic> json) =>
    FocusSessionModel(
      id: json['ID'] as String,
      taskId: json['TaskID'] as String?,
      taskTitle: json['TaskTitle'] as String?,
      userId: json['UserID'] as String,
      duration: (json['Duration'] as num).toInt(),
      status: $enumDecode(_$SessionStatusEnumMap, json['Status']),
      startedAt: DateTime.parse(json['StartedAt'] as String),
      completedAt: json['CompletedAt'] == null
          ? null
          : DateTime.parse(json['CompletedAt'] as String),
      pausedAt: json['PausedAt'] == null
          ? null
          : DateTime.parse(json['PausedAt'] as String),
      totalPaused: (json['TotalPaused'] as num).toInt(),
      createdAt: DateTime.parse(json['CreatedAt'] as String),
    );

Map<String, dynamic> _$FocusSessionModelToJson(FocusSessionModel instance) =>
    <String, dynamic>{
      'ID': instance.id,
      'TaskID': instance.taskId,
      'TaskTitle': instance.taskTitle,
      'UserID': instance.userId,
      'Duration': instance.duration,
      'Status': _$SessionStatusEnumMap[instance.status]!,
      'StartedAt': instance.startedAt.toIso8601String(),
      'CompletedAt': instance.completedAt?.toIso8601String(),
      'PausedAt': instance.pausedAt?.toIso8601String(),
      'TotalPaused': instance.totalPaused,
      'CreatedAt': instance.createdAt.toIso8601String(),
    };

const _$SessionStatusEnumMap = {
  SessionStatus.running: 'RUNNING',
  SessionStatus.completed: 'COMPLETED',
  SessionStatus.cancelled: 'CANCELLED',
  SessionStatus.paused: 'PAUSED',
};
