import 'package:flutter/material.dart';

import 'package:ui_kit/src/theme/text_styles.dart';

/// A labeled slider for selecting a geofence radius.
///
/// Range: 100 m – 5000 m. Displays a human-readable label that switches
/// between metres and kilometres (e.g. '250 m', '1.2 km'). The
/// [onRadiusChanged] callback fires with the new value in metres.
///
/// Example:
/// ```dart
/// RadiusSlider(
///   radiusMeters: _radius,
///   onRadiusChanged: (meters) => setState(() => _radius = meters),
/// )
/// ```
class RadiusSlider extends StatelessWidget {
  /// Creates a [RadiusSlider].
  const RadiusSlider({
    required this.radiusMeters,
    required this.onRadiusChanged,
    super.key,
  });

  /// Minimum selectable radius in metres.
  static const double minRadius = 100;

  /// Maximum selectable radius in metres.
  static const double maxRadius = 5000;

  /// The current radius in metres. Must be between [minRadius] and [maxRadius].
  final double radiusMeters;

  /// Called when the user moves the slider.
  final ValueChanged<double> onRadiusChanged;

  /// Formats [meters] as a human-readable string.
  ///
  /// Values below 1000 m are shown as whole metres (e.g. '250 m').
  /// Values >= 1000 m are shown in kilometres with one decimal place
  /// (e.g. '1.2 km'), dropping the decimal when it is zero (e.g. '2 km').
  static String formatRadius(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    final km = meters / 1000;
    final formatted = km == km.roundToDouble()
        ? '${km.round()} km'
        : '${km.toStringAsFixed(1)} km';
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final clampedValue = radiusMeters.clamp(minRadius, maxRadius);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Radius',
              style: AppTextStyles.itemTitle.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              formatRadius(clampedValue),
              style: AppTextStyles.badge.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Slider(
          value: clampedValue,
          min: minRadius,
          max: maxRadius,
          // 50 m divisions → (5000 - 100) / 50 = 98 divisions
          divisions: ((maxRadius - minRadius) / 50).round(),
          label: formatRadius(clampedValue),
          activeColor: colorScheme.primary,
          inactiveColor: colorScheme.primary.withValues(alpha: 0.24),
          onChanged: onRadiusChanged,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatRadius(minRadius),
                style: AppTextStyles.caption,
              ),
              Text(
                formatRadius(maxRadius),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
