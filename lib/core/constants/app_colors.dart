import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF135BEC);
  static const Color primaryDark = Color(0xFF0F4BC4);
  static const Color primaryLight = Color(0xFF38BDF8);

  // Background
  static const Color backgroundLight = Color(0xFFF6F6F8);
  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceBorder = Color(0xFF333333);

  // Accents
  static const Color accentCoral = Color(0xFFFF5252);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentGreen = Color(0xFF69F0AE);
  static const Color accentAmber = Color(0xFFFFB74D);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF92A4C9);
  static const Color textTertiary = Color(0xFF6B7280);

  // Status Colors
  static const Color statusPending = Color(0xFF2196F3);
  static const Color statusActive = Color(0xFF135BEC);
  static const Color statusBlocked = Color(0xFFFF9800);
  static const Color statusCompleted = Color(0xFF4CAF50);

  // Priority Colors
  static const Map<int, Color> priorityColors = {
    1: Color(0xFFFF5252), // Critical - Coral
    2: Color(0xFFFF9800), // High - Orange
    3: Color(0xFF2196F3), // Medium - Blue
    4: Color(0xFF4CAF50), // Low - Green
    5: Color(0xFF9E9E9E), // Minimal - Gray
  };

  static Color getPriorityColor(int priority) {
    return priorityColors[priority] ?? statusPending;
  }
}
