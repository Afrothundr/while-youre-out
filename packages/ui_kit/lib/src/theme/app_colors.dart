import 'package:flutter/material.dart';

/// Color constants used throughout the app.
abstract final class AppColors {
  /// Eight ARGB color values users can pick for a list's accent color.
  static const List<int> listColors = <int>[
    0xFF0099D9, // sky blue (default)
    0xFF4CAF50, // green
    0xFFFF9800, // orange
    0xFFE91E63, // pink
    0xFF9C27B0, // purple
    0xFF00BCD4, // cyan
    0xFFFF5722, // deep orange
    0xFF607D8B, // blue grey
  ];

  /// Red used for destructive / delete actions.
  static const Color danger = Color(0xFFE53935);
}
