import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:whileyoureout/providers/providers.dart';

/// A modal bottom sheet that lets the user edit the title and color of an
/// existing [TodoList].
///
/// Pre-fills the title field and color picker with the list's current values.
/// Tapping "Save" calls [TodoListRepository.saveList] with the updated fields.
///
/// Example:
/// ```dart
/// await EditListBottomSheet.show(context, list: myList);
/// ```
class EditListBottomSheet extends ConsumerStatefulWidget {
  /// Creates an [EditListBottomSheet] for [list].
  const EditListBottomSheet({required this.list, super.key});

  /// The [TodoList] being edited.
  final TodoList list;

  /// Shows the bottom sheet modally.
  static Future<void> show(BuildContext context, {required TodoList list}) {
    return AppBottomSheet.show<void>(
      context: context,
      child: EditListBottomSheet(list: list),
    );
  }

  @override
  ConsumerState<EditListBottomSheet> createState() =>
      _EditListBottomSheetState();
}

class _EditListBottomSheetState extends ConsumerState<EditListBottomSheet> {
  late final TextEditingController _titleController;
  final _formKey = GlobalKey<FormState>();

  late int _selectedColor;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.list.title);
    _selectedColor = widget.list.color;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      final updated = widget.list.copyWith(
        title: _titleController.text.trim(),
        color: _selectedColor,
      );
      await ref.read(todoListRepositoryProvider).saveList(updated);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save list: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Edit List',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            autofocus: true,
            maxLength: 50,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(50)],
            decoration: const InputDecoration(
              labelText: 'List title',
              counterText: '',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _save(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Color',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          ColorPickerRow(
            selectedColor: _selectedColor,
            onColorChanged: (color) => setState(() => _selectedColor = color),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
