import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:whileyoureout/providers/providers.dart';

/// A modal bottom sheet that lets the user create a new todo list.
///
/// Shows a text field for the list title, a color picker row for accent color
/// selection, and a Save button that calls the create list use case.
class CreateListBottomSheet extends ConsumerStatefulWidget {
  /// Creates a [CreateListBottomSheet].
  const CreateListBottomSheet({super.key});

  /// Shows the bottom sheet modally.
  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show<void>(
      context: context,
      child: const CreateListBottomSheet(),
    );
  }

  @override
  ConsumerState<CreateListBottomSheet> createState() =>
      _CreateListBottomSheetState();
}

class _CreateListBottomSheetState extends ConsumerState<CreateListBottomSheet> {
  final _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _selectedColor = AppColors.listColors.first;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(createListUseCaseProvider).call(
            title: _titleController.text.trim(),
            color: _selectedColor,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create list: $e')),
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
            'New List',
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
              hintText: 'e.g. Grocery run',
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
    );
  }
}
