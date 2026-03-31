import 'package:flutter/material.dart';

import 'package:ui_kit/src/theme/text_styles.dart';

/// A custom checkbox widget that animates a strikethrough on the [label] when
/// [value] is `true`.
///
/// Example:
/// ```dart
/// AppCheckbox(
///   label: 'Buy groceries',
///   value: isDone,
///   onChanged: (v) => setState(() => isDone = v ?? false),
/// )
/// ```
class AppCheckbox extends StatefulWidget {
  /// Creates an [AppCheckbox].
  const AppCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// The text label shown beside the checkbox.
  final String label;

  /// Whether the checkbox is currently checked.
  final bool value;

  /// Called when the user toggles the checkbox.
  final ValueChanged<bool?> onChanged;

  @override
  State<AppCheckbox> createState() => _AppCheckboxState();
}

class _AppCheckboxState extends State<AppCheckbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _strikethrough;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: widget.value ? 1.0 : 0.0,
    );
    _strikethrough = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(AppCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => widget.onChanged(!widget.value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: widget.value,
              onChanged: widget.onChanged,
              activeColor: colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: AnimatedBuilder(
                animation: _strikethrough,
                builder: (context, child) {
                  return _StrikethroughText(
                    text: widget.label,
                    progress: _strikethrough.value,
                    colorScheme: colorScheme,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints the [text] with a strikethrough line that grows from left to right
/// according to [progress] (0.0 → 1.0).
class _StrikethroughText extends StatelessWidget {
  const _StrikethroughText({
    required this.text,
    required this.progress,
    required this.colorScheme,
  });

  final String text;
  final double progress;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StrikethroughPainter(
        progress: progress,
        color: colorScheme.primary,
      ),
      child: Text(
        text,
        style: AppTextStyles.itemTitle.copyWith(
          color: progress > 0.5
              ? colorScheme.onSurface.withValues(alpha: 0.4)
              : colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _StrikethroughPainter extends CustomPainter {
  _StrikethroughPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0.0) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width * progress, y),
      paint,
    );
  }

  @override
  bool shouldRepaint(_StrikethroughPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
