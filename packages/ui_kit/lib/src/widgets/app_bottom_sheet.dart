import 'package:flutter/material.dart';

/// Convenience wrapper around [showModalBottomSheet] with consistent padding
/// and a drag handle.
///
/// Example:
/// ```dart
/// AppBottomSheet.show(
///   context: context,
///   child: Column(
///     children: [
///       Text('Edit List'),
///       // ...
///     ],
///   ),
/// );
/// ```
class AppBottomSheet extends StatelessWidget {
  /// Creates an [AppBottomSheet].
  const AppBottomSheet({
    required this.child,
    super.key,
  });

  /// The content to display inside the bottom sheet.
  final Widget child;

  /// Shows a modal bottom sheet with consistent styling.
  ///
  /// Returns a [Future] that resolves to the value passed to [Navigator.pop]
  /// when the sheet is dismissed, or `null` if it is dismissed without a value.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AppBottomSheet(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          // Shift content above the keyboard when it is visible.
          bottom: viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
