import 'package:flutter/material.dart';

import 'package:ui_kit/src/theme/text_styles.dart';

/// A styled list tile representing a todo list.
///
/// Displays a colored circle on the leading edge, the list [title], an
/// optional trailing badge showing the number of incomplete items, and an
/// optional location-pin icon when a geofence is attached.
class AppListTile extends StatelessWidget {
  /// Creates an [AppListTile].
  const AppListTile({
    required this.title,
    required this.color,
    super.key,
    this.incompleteCount = 0,
    this.hasGeofence = false,
    this.onTap,
    this.trailing,
  });

  /// The list title displayed in the tile.
  final String title;

  /// The ARGB integer color used for the leading color dot.
  final int color;

  /// Number of incomplete items. Badge is hidden when this is 0.
  final int incompleteCount;

  /// Whether a geofence is attached to this list. Shows a pin icon when true.
  final bool hasGeofence;

  /// Called when the tile is tapped.
  final VoidCallback? onTap;

  /// An optional widget appended after the badge/geofence icons in the
  /// trailing slot. Intended for drag handles or other action controls.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: _ColorDot(color: color),
      title: Text(title, style: AppTextStyles.listTitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasGeofence)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.location_on, size: 16),
            ),
          if (incompleteCount > 0) _Badge(count: incompleteCount),
          if (trailing != null) ...[
            const SizedBox(width: 4),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// A 12 px filled circle rendered in [color].
class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final int color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: Color(color),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// A small badge showing the incomplete item [count].
class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.badge.copyWith(color: colorScheme.onPrimary),
      ),
    );
  }
}
