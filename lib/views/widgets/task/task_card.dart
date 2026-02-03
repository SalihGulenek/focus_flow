import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final bool swipeable;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onComplete,
    this.swipeable = true,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == TaskStatus.completed;
    final isBlocked = task.status == TaskStatus.blocked;

    Widget card = GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: task.priorityColor,
              width: 4,
            ),
          ),
        ),
        child: Opacity(
          opacity: isCompleted ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getIconBackgroundColor(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: _getIconColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (task.priority <= 2) ...[
                            const SizedBox(width: 8),
                            _buildPriorityBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (task.dueDate != null) ...[
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDueDate(task.dueDate!),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (isBlocked) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.statusBlocked.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    size: 12,
                                    color: AppColors.statusBlocked,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Blocked',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.statusBlocked,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (task.hasSubtasks)
                            Text(
                              '${task.completedSubtasksCount}/${task.subtasks.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Checkbox
                if (!isBlocked)
                  GestureDetector(
                    onTap: isCompleted ? null : onComplete,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.statusCompleted
                            : Colors.transparent,
                        border: Border.all(
                          color: isCompleted
                              ? AppColors.statusCompleted
                              : AppColors.textTertiary,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!swipeable || isBlocked) return card;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        if (!isCompleted) {
          onComplete();
        }
        return false;
      },
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.accentGreen.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.check_circle,
          color: AppColors.accentGreen,
        ),
      ),
      child: card,
    );
  }

  Widget _buildPriorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: task.priorityColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        task.priorityLabel,
        style: TextStyle(
          fontSize: 10,
          color: task.priorityColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (task.status) {
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.active:
        return Icons.play_circle_filled;
      case TaskStatus.blocked:
        return Icons.lock;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  Color _getIconColor() {
    switch (task.status) {
      case TaskStatus.completed:
        return AppColors.statusCompleted;
      case TaskStatus.active:
        return AppColors.statusActive;
      case TaskStatus.blocked:
        return AppColors.statusBlocked;
      default:
        return AppColors.textTertiary;
    }
  }

  Color _getIconBackgroundColor() {
    return _getIconColor().withOpacity(0.15);
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(date.year, date.month, date.day);

    if (dueDay == today) {
      return 'Today ${_formatTime(date)}';
    } else if (dueDay == today.add(const Duration(days: 1))) {
      return 'Tomorrow ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month} ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
