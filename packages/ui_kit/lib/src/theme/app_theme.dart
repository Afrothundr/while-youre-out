import 'package:flutter/material.dart';

import 'package:ui_kit/src/theme/text_styles.dart';

/// Provides the app's [ThemeData] for light and dark modes.
abstract final class AppTheme {
  // blue — same as the first entry in AppColors.listColors (0xFF2196F3)
  static const Color _seedColor = Color(0xFF2196F3);

  /// Light theme using Material 3.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
        ),
        textTheme: _textTheme,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );

  /// Dark theme using Material 3.
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
        textTheme: _textTheme,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );

  static TextTheme get _textTheme => const TextTheme(
        titleLarge: AppTextStyles.listTitle,
        titleMedium: AppTextStyles.itemTitle,
        labelSmall: AppTextStyles.badge,
        bodySmall: AppTextStyles.caption,
      );
}
