import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'tag_model.dart';

part 'task_model.g.dart';

enum TaskStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('ACTIVE')
  active,
  @JsonValue('BLOCKED')
  blocked,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('ARCHIVED')
  archived,
}

enum TaskPriority {
  critical(1),
  high(2),
  medium(3),
  low(4),
  minimal(5);

  final int value;
  const TaskPriority(this.value);

  static TaskPriority fromValue(int value) {
    return TaskPriority.values.firstWhere((p) => p.value == value, orElse: () => TaskPriority.medium);
  }
}

@JsonSerializable()
class TaskModel {
  @JsonKey(name: 'ID')
  final String id;
  @JsonKey(name: 'UserID')
  final String userId;
  @JsonKey(name: 'Title')
  final String title;
  @JsonKey(name: 'Description')
  final String? description;
  @JsonKey(name: 'Status')
  final TaskStatus status;
  @JsonKey(name: 'Priority')
  final int priority;
  @JsonKey(name: 'DueDate')
  final DateTime? dueDate;
  @JsonKey(name: 'IsRecurring')
  final bool isRecurring;
  @JsonKey(name: 'RecurrenceRule')
  final String? recurrenceRule;
  @JsonKey(name: 'RecurrenceEnd')
  final DateTime? recurrenceEnd;
  @JsonKey(name: 'ParentID')
  final String? parentId;
  @JsonKey(name: 'CompletedAt')
  final DateTime? completedAt;
  @JsonKey(name: 'CreatedAt')
  final DateTime createdAt;
  @JsonKey(name: 'UpdatedAt')
  final DateTime updatedAt;
  @JsonKey(name: 'Subtasks', defaultValue: [])
  final List<TaskModel> subtasks;
  @JsonKey(name: 'BlockedBy', defaultValue: [])
  final List<TaskDependencyModel> blockedBy;
  @JsonKey(name: 'Tags', defaultValue: [])
  final List<TagModel> tags;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.isRecurring,
    this.recurrenceRule,
    this.recurrenceEnd,
    this.parentId,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.subtasks = const [],
    this.blockedBy = const [],
    this.tags = const [],
  });

  // Computed properties
  bool get isCompleted => status == TaskStatus.completed;
  bool get isBlocked => status == TaskStatus.blocked;
  bool get isActive => status == TaskStatus.active;
  bool get isSubtask => parentId != null;
  bool get hasSubtasks => subtasks.isNotEmpty;
  bool get hasDependencies => blockedBy.isNotEmpty;

  String get priorityLabel {
    switch (TaskPriority.fromValue(priority)) {
      case TaskPriority.critical:
        return 'Critical';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.minimal:
        return 'Minimal';
    }
  }

  Color get priorityColor => AppColors.getPriorityColor(priority);

  Color get statusColor {
    switch (status) {
      case TaskStatus.pending:
        return AppColors.statusPending;
      case TaskStatus.active:
        return AppColors.statusActive;
      case TaskStatus.blocked:
        return AppColors.statusBlocked;
      case TaskStatus.completed:
        return AppColors.statusCompleted;
      case TaskStatus.archived:
        return AppColors.textTertiary;
    }
  }

  double get progress {
    if (subtasks.isEmpty) return isCompleted ? 1.0 : 0.0;
    final completed = subtasks.where((s) => s.isCompleted).length;
    return completed / subtasks.length;
  }

  int get completedSubtasksCount => subtasks.where((s) => s.isCompleted).length;

  factory TaskModel.fromJson(Map<String, dynamic> json) => _$TaskModelFromJson(json);
  Map<String, dynamic> toJson() => _$TaskModelToJson(this);

  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'status': status.name.toUpperCase(),
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'is_recurring': isRecurring ? 1 : 0,
      'recurrence_rule': recurrenceRule,
      'recurrence_end': recurrenceEnd?.toIso8601String(),
      'parent_id': parentId,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced': 0,
    };
  }

  factory TaskModel.fromDb(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: TaskStatus.values.firstWhere((s) => s.name.toUpperCase() == map['status'], orElse: () => TaskStatus.pending),
      priority: map['priority'] as int,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      isRecurring: map['is_recurring'] == 1,
      recurrenceRule: map['recurrence_rule'] as String?,
      recurrenceEnd: map['recurrence_end'] != null ? DateTime.parse(map['recurrence_end'] as String) : null,
      parentId: map['parent_id'] as String?,
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    TaskStatus? status,
    int? priority,
    DateTime? dueDate,
    bool? isRecurring,
    String? recurrenceRule,
    DateTime? recurrenceEnd,
    String? parentId,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TaskModel>? subtasks,
    List<TaskDependencyModel>? blockedBy,
    List<TagModel>? tags,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      recurrenceEnd: recurrenceEnd ?? this.recurrenceEnd,
      parentId: parentId ?? this.parentId,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subtasks: subtasks ?? this.subtasks,
      blockedBy: blockedBy ?? this.blockedBy,
      tags: tags ?? this.tags,
    );
  }
}

@JsonSerializable()
class TaskDependencyModel {
  @JsonKey(name: 'BlockerTaskID')
  final String blockerTaskId;
  @JsonKey(name: 'BlockerTitle')
  final String? blockerTitle;
  @JsonKey(name: 'BlockerStatus')
  final TaskStatus? blockerStatus;
  @JsonKey(name: 'CreatedAt')
  final DateTime createdAt;

  TaskDependencyModel({required this.blockerTaskId, this.blockerTitle, this.blockerStatus, required this.createdAt});

  factory TaskDependencyModel.fromJson(Map<String, dynamic> json) => _$TaskDependencyModelFromJson(json);
  Map<String, dynamic> toJson() => _$TaskDependencyModelToJson(this);
}
