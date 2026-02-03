// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskModel _$TaskModelFromJson(Map<String, dynamic> json) => TaskModel(
  id: json['ID'] as String,
  userId: json['UserID'] as String,
  title: json['Title'] as String,
  description: json['Description'] as String?,
  status: $enumDecode(_$TaskStatusEnumMap, json['Status']),
  priority: (json['Priority'] as num).toInt(),
  dueDate: json['DueDate'] == null
      ? null
      : DateTime.parse(json['DueDate'] as String),
  isRecurring: json['IsRecurring'] as bool,
  recurrenceRule: json['RecurrenceRule'] as String?,
  recurrenceEnd: json['RecurrenceEnd'] == null
      ? null
      : DateTime.parse(json['RecurrenceEnd'] as String),
  parentId: json['ParentID'] as String?,
  completedAt: json['CompletedAt'] == null
      ? null
      : DateTime.parse(json['CompletedAt'] as String),
  createdAt: DateTime.parse(json['CreatedAt'] as String),
  updatedAt: DateTime.parse(json['UpdatedAt'] as String),
  subtasks:
      (json['Subtasks'] as List<dynamic>?)
          ?.map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  blockedBy:
      (json['BlockedBy'] as List<dynamic>?)
          ?.map((e) => TaskDependencyModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  tags:
      (json['Tags'] as List<dynamic>?)
          ?.map((e) => TagModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$TaskModelToJson(TaskModel instance) => <String, dynamic>{
  'ID': instance.id,
  'UserID': instance.userId,
  'Title': instance.title,
  'Description': instance.description,
  'Status': _$TaskStatusEnumMap[instance.status]!,
  'Priority': instance.priority,
  'DueDate': instance.dueDate?.toIso8601String(),
  'IsRecurring': instance.isRecurring,
  'RecurrenceRule': instance.recurrenceRule,
  'RecurrenceEnd': instance.recurrenceEnd?.toIso8601String(),
  'ParentID': instance.parentId,
  'CompletedAt': instance.completedAt?.toIso8601String(),
  'CreatedAt': instance.createdAt.toIso8601String(),
  'UpdatedAt': instance.updatedAt.toIso8601String(),
  'Subtasks': instance.subtasks,
  'BlockedBy': instance.blockedBy,
  'Tags': instance.tags,
};

const _$TaskStatusEnumMap = {
  TaskStatus.pending: 'PENDING',
  TaskStatus.active: 'ACTIVE',
  TaskStatus.blocked: 'BLOCKED',
  TaskStatus.completed: 'COMPLETED',
  TaskStatus.archived: 'ARCHIVED',
};

TaskDependencyModel _$TaskDependencyModelFromJson(Map<String, dynamic> json) =>
    TaskDependencyModel(
      blockerTaskId: json['BlockerTaskID'] as String,
      blockerTitle: json['BlockerTitle'] as String?,
      blockerStatus: $enumDecodeNullable(
        _$TaskStatusEnumMap,
        json['BlockerStatus'],
      ),
      createdAt: DateTime.parse(json['CreatedAt'] as String),
    );

Map<String, dynamic> _$TaskDependencyModelToJson(
  TaskDependencyModel instance,
) => <String, dynamic>{
  'BlockerTaskID': instance.blockerTaskId,
  'BlockerTitle': instance.blockerTitle,
  'BlockerStatus': _$TaskStatusEnumMap[instance.blockerStatus],
  'CreatedAt': instance.createdAt.toIso8601String(),
};
