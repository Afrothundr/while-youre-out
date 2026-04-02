import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:whileyoureout/providers/providers.dart';
import 'package:whileyoureout/screens/map_picker/map_picker_view_model.dart';

// ---------------------------------------------------------------------------
// Bottom sheet
// ---------------------------------------------------------------------------

/// Bottom sheet overlay for the map picker screen.
///
/// Displays a label text field, a radius slider, a Save Location button, and
/// — when the list already has a geofence — a Remove Location button.
///
/// Extracted from the private `_BottomSheet` widget to enable isolated widget
/// testing.
class MapPickerBottomSheet extends ConsumerStatefulWidget {
  /// Creates a [MapPickerBottomSheet] for the list identified by [listId].
  const MapPickerBottomSheet({
    required this.listId,
    required this.viewModel,
    this.initialChildSize = 0.3,
    super.key,
  });

  /// The ID of the [TodoList] whose geofence location is being edited.
  final String listId;

  /// The view-model that owns the pin, radius, label, and saving state.
  final MapPickerViewModel viewModel;

  /// The initial fraction of the parent height occupied by the sheet.
  ///
  /// Defaults to 0.3 (the production value). Pass a larger value in widget
  /// tests to ensure the Save button is visible without needing to drag the
  /// sheet open.
  final double initialChildSize;

  @override
  ConsumerState<MapPickerBottomSheet> createState() =>
      _MapPickerBottomSheetState();
}

class _MapPickerBottomSheetState extends ConsumerState<MapPickerBottomSheet> {
  late final TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.viewModel.label)
      ..selection = TextSelection.collapsed(
        offset: widget.viewModel.label.length,
      );
    widget.viewModel.addListener(_syncLabelFromViewModel);
  }

  /// Keeps the label controller in sync when the view model's label is updated
  /// externally (e.g. by auto-suggest or autocomplete selection). Skips the
  /// update if the controller already matches or the user has an active
  /// selection (mid-edit).
  void _syncLabelFromViewModel() {
    if (_labelController.text != widget.viewModel.label &&
        !_labelController.selection.isValid) {
      _labelController
        ..text = widget.viewModel.label
        ..selection = TextSelection.collapsed(
          offset: widget.viewModel.label.length,
        );
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_syncLabelFromViewModel);
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    return DraggableScrollableSheet(
      initialChildSize: widget.initialChildSize,
      minChildSize: 0.15,
      maxChildSize: 0.6,
      snap: true,
      builder: (context, scrollController) {
        return Material(
          elevation: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Label field
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Location label',
                    hintText: 'e.g. Home, Supermarket\u2026',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  controller: _labelController,
                  onChanged: viewModel.updateLabel,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Radius slider
                RadiusSlider(
                  radiusMeters: viewModel.radiusMeters,
                  onRadiusChanged: viewModel.updateRadius,
                ),
                const SizedBox(height: 20),

                // Save button
                FilledButton.icon(
                  onPressed:
                      viewModel.selectedLatLng == null || viewModel.isSaving
                          ? null
                          : () => _onSave(context),
                  icon: viewModel.isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save Location'),
                ),

                // Remove button — only if list already has a geofence
                MapPickerRemoveButton(
                  listId: widget.listId,
                  viewModel: viewModel,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSave(BuildContext context) async {
    await widget.viewModel.saveLocation(
      listId: widget.listId,
      assignLocation: AssignLocationUseCase(
        ref.read(todoListRepositoryProvider),
        ref.read(geofenceRepositoryProvider),
      ),
      registerGeofence: RegisterGeofenceUseCase(
        ref.read(geofenceRepositoryProvider),
        ref.read(geofenceServiceProvider),
      ),
      listRepo: ref.read(todoListRepositoryProvider),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location saved')),
      );
      context.pop();
    }
  }
}

// ---------------------------------------------------------------------------
// Remove button (conditionally visible)
// ---------------------------------------------------------------------------

/// Conditionally renders a 'Remove Location' button when the list identified
/// by [listId] already has a geofence assigned.
///
/// Extracted from the private `_RemoveButton` widget to enable isolated widget
/// testing.
class MapPickerRemoveButton extends ConsumerWidget {
  /// Creates a [MapPickerRemoveButton] for the list identified by [listId].
  const MapPickerRemoveButton({
    required this.listId,
    required this.viewModel,
    super.key,
  });

  /// The ID of the [TodoList] to check for an existing geofence.
  final String listId;

  /// The view-model that owns the saving state.
  final MapPickerViewModel viewModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use a StreamProvider instead of a one-shot Future so that the widget
    // subscribes to the reactive list stream.  A FutureBuilder whose future
    // is constructed inside build() creates a brand-new Future on every
    // rebuild, which resets ConnectionState to waiting and briefly hides the
    // button — a visible flicker whenever isSaving toggles.
    final asyncList = ref.watch(listByIdProvider(listId));
    final hasGeofence = asyncList.valueOrNull?.geofenceId != null;
    if (!hasGeofence) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          onPressed: viewModel.isSaving
              ? null
              : () => _onRemove(context, ref),
          icon: const Icon(Icons.location_off_outlined),
          label: const Text('Remove Location'),
        ),
      ],
    );
  }

  Future<void> _onRemove(BuildContext context, WidgetRef ref) async {
    await viewModel.removeLocation(
      listId: listId,
      listRepo: ref.read(todoListRepositoryProvider),
      geofenceRepo: ref.read(geofenceRepositoryProvider),
      unregisterGeofence: UnregisterGeofenceUseCase(
        ref.read(geofenceRepositoryProvider),
        ref.read(geofenceServiceProvider),
      ),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location removed')),
      );
      context.pop();
    }
  }
}
