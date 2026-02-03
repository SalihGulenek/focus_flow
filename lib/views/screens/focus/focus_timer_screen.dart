import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/locator.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/focus_viewmodel.dart';

class FocusTimerScreen extends StatefulWidget {
  final String? taskId;
  final String? taskTitle;

  const FocusTimerScreen({
    super.key,
    this.taskId,
    this.taskTitle,
  });

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  final _authViewModel = locator<AuthViewModel>();
  final _focusViewModel = locator<FocusViewModel>();

  int _selectedDuration = 25;
  final _durations = [15, 25, 45, 60];

  @override
  void initState() {
    super.initState();
    _focusViewModel.loadActiveSession(_authViewModel.currentUser!.id);
  }

  Future<void> _startSession() async {
    await _focusViewModel.startSession(
      userId: _authViewModel.currentUser!.id,
      taskId: widget.taskId,
      duration: _selectedDuration,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text(AppStrings.focusTimer),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Observer(
        builder: (_) {
          if (_focusViewModel.hasActiveSession) {
            return _buildActiveSession();
          }
          return _buildSessionSetup();
        },
      ),
    );
  }

  Widget _buildSessionSetup() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Spacer(),

          // Task info
          if (widget.taskTitle != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.task_alt,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Focus on',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          widget.taskTitle!,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],

          // Timer display (preview)
          Text(
            '$_selectedDuration:00',
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w200,
              color: AppColors.textPrimary,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 40),

          // Duration selector
          Text(
            'Select Duration',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _durations.map((duration) {
              final isSelected = _selectedDuration == duration;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDuration = duration),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$duration',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const Spacer(),

          // Start button
          Observer(
            builder: (_) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _focusViewModel.isLoading ? null : _startSession,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _focusViewModel.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.startFocus,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildActiveSession() {
    return Observer(
      builder: (_) {
        final session = _focusViewModel.activeSession;
        if (session == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),

              // Task info
              if (session.taskTitle != null || widget.taskTitle != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    session.taskTitle ?? widget.taskTitle ?? 'Focus Session',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],

              // Circular timer
              SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    SizedBox(
                      width: 280,
                      height: 280,
                      child: CircularProgressIndicator(
                        value: 1,
                        strokeWidth: 8,
                        backgroundColor: AppColors.surfaceBorder.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.surfaceBorder.withOpacity(0.3),
                        ),
                      ),
                    ),
                    // Progress circle
                    SizedBox(
                      width: 280,
                      height: 280,
                      child: Transform.rotate(
                        angle: -math.pi / 2,
                        child: CircularProgressIndicator(
                          value: _focusViewModel.progress,
                          strokeWidth: 8,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _focusViewModel.isPaused
                                ? AppColors.accentOrange
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    // Time display
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _focusViewModel.formattedTime,
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w200,
                            color: AppColors.textPrimary,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _focusViewModel.isPaused ? 'PAUSED' : 'FOCUS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _focusViewModel.isPaused
                                ? AppColors.accentOrange
                                : AppColors.primary,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cancel button
                  _buildControlButton(
                    icon: Icons.stop,
                    label: AppStrings.stop,
                    onTap: () async {
                      final confirmed = await _showCancelDialog();
                      if (confirmed == true) {
                        await _focusViewModel.cancelSession();
                      }
                    },
                    color: AppColors.accentCoral,
                  ),
                  const SizedBox(width: 24),
                  // Play/Pause button
                  _buildMainControlButton(
                    icon: _focusViewModel.isPaused
                        ? Icons.play_arrow
                        : Icons.pause,
                    onTap: () {
                      if (_focusViewModel.isPaused) {
                        _focusViewModel.resumeSession();
                      } else {
                        _focusViewModel.pauseSession();
                      }
                    },
                  ),
                  const SizedBox(width: 24),
                  // Complete button
                  _buildControlButton(
                    icon: Icons.check,
                    label: 'Done',
                    onTap: () async {
                      await _focusViewModel.completeSession();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(AppStrings.sessionCompleted),
                            backgroundColor: AppColors.statusCompleted,
                          ),
                        );
                      }
                    },
                    color: AppColors.statusCompleted,
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 40),
      ),
    );
  }

  Future<bool?> _showCancelDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Cancel Session?'),
        content: const Text(
          'Your progress will be lost. Are you sure you want to cancel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentCoral),
            child: const Text('Cancel Session'),
          ),
        ],
      ),
    );
  }
}
