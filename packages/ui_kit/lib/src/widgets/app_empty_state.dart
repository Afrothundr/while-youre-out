import 'package:flutter/material.dart';

import 'package:ui_kit/src/theme/text_styles.dart';

/// A centered empty-state widget with an icon, headline, body copy, and an
/// optional action widget (e.g. a button to create the first item).
///
/// Example:
/// ```dart
/// AppEmptyState(
///   icon: Icons.checklist,
///   headline: 'No lists yet',
///   body: 'Tap the + button to create your first list.',
///   action: ElevatedButton(
///     onPressed: onCreate,
///     child: const Text('Create list'),
///   ),
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  /// Creates an [AppEmptyState].
  const AppEmptyState({
    required this.icon,
    required this.headline,
    required this.body,
    super.key,
    this.action,
  });

  /// The icon displayed at the top of the empty state.
  final IconData icon;

  /// The primary headline text.
  final String headline;

  /// The secondary body copy providing context or guidance.
  final String body;

  /// An optional action widget, typically a button, rendered below the body.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 72,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              headline,
              style: AppTextStyles.listTitle.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: AppTextStyles.caption.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
