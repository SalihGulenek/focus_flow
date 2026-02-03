import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/locator.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/task_viewmodel.dart';

class AddTaskScreen extends StatefulWidget {
  final String? parentId;

  const AddTaskScreen({super.key, this.parentId});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _authViewModel = locator<AuthViewModel>();
  final _taskViewModel = locator<TaskViewModel>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _selectedPriority = 3;
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;
  bool _isRecurring = false;
  String? _recurrenceRule;

  final _priorities = [
    (value: 1, label: 'Critical', color: AppColors.priorityColors[1]!),
    (value: 2, label: 'High', color: AppColors.priorityColors[2]!),
    (value: 3, label: 'Medium', color: AppColors.priorityColors[3]!),
    (value: 4, label: 'Low', color: AppColors.priorityColors[4]!),
    (value: 5, label: 'Minimal', color: AppColors.priorityColors[5]!),
  ];

  final _recurrenceOptions = [
    (value: 'DAILY', label: AppStrings.daily),
    (value: 'WEEKLY', label: AppStrings.weekly),
    (value: 'WEEKDAYS', label: AppStrings.weekdays),
    (value: 'MONTHLY', label: AppStrings.monthly),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    if (_authViewModel.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated. Please login again.')),
      );
      return;
    }

    DateTime? dueDateTime;
    if (_selectedDueDate != null) {
      dueDateTime = DateTime(
        _selectedDueDate!.year,
        _selectedDueDate!.month,
        _selectedDueDate!.day,
        _selectedDueTime?.hour ?? 12,
        _selectedDueTime?.minute ?? 0,
      );
    }

    final success = await _taskViewModel.createTask(
      userId: _authViewModel.currentUser!.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      priority: _selectedPriority,
      dueDate: dueDateTime,
      isRecurring: _isRecurring,
      recurrenceRule: _isRecurring ? _recurrenceRule : null,
      parentId: widget.parentId,
    );

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Text(widget.parentId != null ? 'Add Subtask' : AppStrings.addTask),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          Observer(
            builder: (_) {
              return TextButton(
                onPressed: _taskViewModel.isLoading ? null : _handleSave,
                child: _taskViewModel.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title input
            TextField(
              controller: _titleController,
              style: Theme.of(context).textTheme.headlineSmall,
              decoration: const InputDecoration(
                hintText: 'What needs to be done?',
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppColors.textTertiary),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const Divider(color: AppColors.surfaceBorder),
            const SizedBox(height: 16),

            // Description input
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add description...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppColors.textTertiary),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Priority selector
            Text(
              'Priority',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _priorities.map((p) {
                final isSelected = _selectedPriority == p.value;
                return ChoiceChip(
                  label: Text(p.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedPriority = p.value);
                    }
                  },
                  selectedColor: p.color.withOpacity(0.3),
                  labelStyle: TextStyle(
                    color: isSelected ? p.color : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? p.color : AppColors.surfaceBorder,
                  ),
                  backgroundColor: AppColors.surfaceDark,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Due date
            Text(
              'Due Date',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDueDate != null
                                ? '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}'
                                : 'Select date',
                            style: TextStyle(
                              color: _selectedDueDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDueTime != null
                                ? '${_selectedDueTime!.hour.toString().padLeft(2, '0')}:${_selectedDueTime!.minute.toString().padLeft(2, '0')}'
                                : 'Select time',
                            style: TextStyle(
                              color: _selectedDueTime != null
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recurrence
            if (widget.parentId == null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recurring Task',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Switch(
                    value: _isRecurring,
                    onChanged: (value) {
                      setState(() {
                        _isRecurring = value;
                        if (!value) _recurrenceRule = null;
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
              if (_isRecurring) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: _recurrenceOptions.map((option) {
                    final isSelected = _recurrenceRule == option.value;
                    return ChoiceChip(
                      label: Text(option.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _recurrenceRule = selected ? option.value : null;
                        });
                      },
                      selectedColor: AppColors.primary.withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                      ),
                      backgroundColor: AppColors.surfaceDark,
                    );
                  }).toList(),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surfaceDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _selectedDueDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedDueTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surfaceDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() => _selectedDueTime = time);
    }
  }
}
