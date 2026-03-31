import 'package:flutter/material.dart';

import 'package:ui_kit/src/theme/app_colors.dart';

/// A horizontal scrollable row of color circles for picking a list accent
/// color.
///
/// Displays the eight colors defined in [AppColors.listColors]. Tapping a
/// circle selects it and shows a checkmark overlay. The [onColorChanged]
/// callback is fired with the selected ARGB integer value.
///
/// Example:
/// ```dart
/// ColorPickerRow(
///   selectedColor: _color,
///   onColorChanged: (color) => setState(() => _color = color),
/// )
/// ```
class ColorPickerRow extends StatelessWidget {
  /// Creates a [ColorPickerRow].
  const ColorPickerRow({
    required this.selectedColor,
    required this.onColorChanged,
    super.key,
  });

  /// The currently selected ARGB color value.
  final int selectedColor;

  /// Called when the user taps a color circle.
  final ValueChanged<int> onColorChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: AppColors.listColors.map((color) {
          final isSelected = color == selectedColor;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: _ColorCircle(
              color: color,
              isSelected: isSelected,
              onTap: () => onColorChanged(color),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// A tappable color circle with an optional checkmark overlay when selected.
class _ColorCircle extends StatelessWidget {
  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final int color;
  final bool isSelected;
  final VoidCallback onTap;

  static const double _size = 36;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: Color(color),
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(color).withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
          border: isSelected
              ? Border.all(
                  color: Colors.white,
                  width: 2.5,
                )
              : null,
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 18,
              )
            : null,
      ),
    );
  }
}
