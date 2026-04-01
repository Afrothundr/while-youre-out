import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:whileyoureout/providers/providers.dart';
import 'package:whileyoureout/screens/map_picker/map_picker_view_model.dart';
import 'package:whileyoureout/services/places_suggestion_service.dart';

// ---------------------------------------------------------------------------
// Default fallback location — San Francisco
// ---------------------------------------------------------------------------

const _kDefaultCenter = LatLng(37.7749, -122.4194);
const _kDefaultZoom = 14.0;

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Per-list [MapPickerViewModel] provider.
final _mapPickerViewModelProvider =
    ChangeNotifierProvider.autoDispose.family<MapPickerViewModel, String>(
  (ref, listId) => MapPickerViewModel(),
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Full-screen map that lets the user place a pin to assign a geofence
/// location to a todo list.
///
/// Route: `/list/:listId/map`
class MapPickerScreen extends ConsumerStatefulWidget {
  /// Creates a [MapPickerScreen] for the list identified by [listId].
  const MapPickerScreen({required this.listId, super.key});

  /// The ID of the [TodoList] whose geofence location is being edited.
  final String listId;

  @override
  ConsumerState<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends ConsumerState<MapPickerScreen> {
  final Completer<gm.GoogleMapController> _mapControllerCompleter =
      Completer();
  LatLng _center = _kDefaultCenter;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  /// Determines the initial map center:
  /// 1. Uses the existing geofence location if one is assigned.
  /// 2. Falls back to the device's current position.
  /// 3. Falls back to [_kDefaultCenter] if location is unavailable.
  Future<void> _initMap() async {
    // Load existing geofence first.
    final list = await ref
        .read(todoListRepositoryProvider)
        .getListById(widget.listId);
    if (list?.geofenceId != null) {
      final region = await ref
          .read(geofenceRepositoryProvider)
          .getGeofenceById(list!.geofenceId!);
      if (region != null && mounted) {
        ref
            .read(_mapPickerViewModelProvider(widget.listId))
            .prefill(region);
        _moveTo(LatLng(region.latitude, region.longitude));
        return;
      }
    }

    // Try current device location.
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (mounted) {
        _moveTo(LatLng(position.latitude, position.longitude));
      }
    } catch (_) {
      // Permission denied or error — stay on default center.
    }

    // Auto-suggest: search for a nearby place matching the list title.
    // This runs after the map is already positioned, so it is non-blocking
    // from the user's perspective. If no match is found, nothing changes.
    try {
      final listForSuggest = await ref
          .read(todoListRepositoryProvider)
          .getListById(widget.listId);
      if (listForSuggest != null && mounted) {
        await ref
            .read(_mapPickerViewModelProvider(widget.listId))
            .tryAutoSuggestLocation(
              listTitle: listForSuggest.title,
              lat: _center.latitude,
              lng: _center.longitude,
              service: ref.read(placesSuggestionServiceProvider),
            );
        // If a suggestion was found, move the camera to it.
        final vm = ref.read(_mapPickerViewModelProvider(widget.listId));
        if (vm.autoSuggestion != null && mounted) {
          _moveTo(
            LatLng(
              vm.autoSuggestion!.latitude,
              vm.autoSuggestion!.longitude,
            ),
          );
        }
      }
    } catch (_) {
      // Auto-suggest is best-effort; never crash _initMap over it.
    }
  }

  void _moveTo(LatLng latLng) {
    setState(() => _center = latLng);
    if (_mapReady) {
      _mapControllerCompleter.future.then((controller) {
        controller.animateCamera(
          gm.CameraUpdate.newLatLng(
            gm.LatLng(latLng.latitude, latLng.longitude),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(_mapPickerViewModelProvider(widget.listId));

    return Scaffold(
      body: Stack(
        children: [
          // ----------------------------------------------------------------
          // Map layer
          // ----------------------------------------------------------------
          _MapLayer(
            center: _center,
            mapControllerCompleter: _mapControllerCompleter,
            viewModel: viewModel,
            onMapReady: () => setState(() => _mapReady = true),
          ),

          // ----------------------------------------------------------------
          // Back button
          // ----------------------------------------------------------------
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: SafeArea(
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                  tooltip: 'Back',
                ),
              ),
            ),
          ),

          // ----------------------------------------------------------------
          // Suggestion card — shown when Places API found a nearby match
          // ----------------------------------------------------------------
          if (viewModel.autoSuggestion != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 64,
              left: 16,
              right: 16,
              child: _SuggestionCard(
                suggestion: viewModel.autoSuggestion!,
                onDismiss: viewModel.dismissAutoSuggestion,
              ),
            ),

          // ----------------------------------------------------------------
          // Bottom sheet
          // ----------------------------------------------------------------
          _BottomSheet(
            listId: widget.listId,
            viewModel: viewModel,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Map layer
// ---------------------------------------------------------------------------

class _MapLayer extends StatelessWidget {
  const _MapLayer({
    required this.center,
    required this.mapControllerCompleter,
    required this.viewModel,
    required this.onMapReady,
  });

  final LatLng center;
  final Completer<gm.GoogleMapController> mapControllerCompleter;
  final MapPickerViewModel viewModel;
  final VoidCallback onMapReady;

  @override
  Widget build(BuildContext context) {
    final pin = viewModel.selectedLatLng;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return gm.GoogleMap(
      initialCameraPosition: gm.CameraPosition(
        target: gm.LatLng(center.latitude, center.longitude),
        zoom: _kDefaultZoom,
      ),
      onMapCreated: (controller) {
        if (!mapControllerCompleter.isCompleted) {
          mapControllerCompleter.complete(controller);
        }
        onMapReady();
      },
      onTap: (gm.LatLng latLng) => viewModel.selectLocation(
        LatLng(latLng.latitude, latLng.longitude),
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      circles: pin == null
          ? {}
          : {
              gm.Circle(
                circleId: const gm.CircleId('geofence'),
                center: gm.LatLng(pin.latitude, pin.longitude),
                radius: viewModel.radiusMeters,
                fillColor: primaryColor.withValues(alpha: 0.15),
                strokeColor: primaryColor,
                strokeWidth: 2,
              ),
            },
      markers: pin == null
          ? {}
          : {
              gm.Marker(
                markerId: const gm.MarkerId('pin'),
                position: gm.LatLng(pin.latitude, pin.longitude),
              ),
            },
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet
// ---------------------------------------------------------------------------

class _BottomSheet extends ConsumerStatefulWidget {
  const _BottomSheet({
    required this.listId,
    required this.viewModel,
  });

  final String listId;
  final MapPickerViewModel viewModel;

  @override
  ConsumerState<_BottomSheet> createState() => _BottomSheetState();
}

class _BottomSheetState extends ConsumerState<_BottomSheet> {
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
  /// externally (e.g. by auto-suggest). Skips the update if the controller
  /// already matches or the user has an active selection (mid-edit).
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
      initialChildSize: 0.3,
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
                    hintText: 'e.g. Home, Supermarket…',
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
                _RemoveButton(
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
// Suggestion card
// ---------------------------------------------------------------------------

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.onDismiss,
  });

  final PlaceSuggestion suggestion;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final km = (suggestion.distanceMeters / 1000).toStringAsFixed(1);
    return Card(
      elevation: 4,
      child: ListTile(
        leading: const Icon(Icons.auto_awesome_outlined),
        title: Text(
          suggestion.name,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Text('$km km away — tap elsewhere to change'),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Dismiss suggestion',
          onPressed: onDismiss,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Remove button (conditionally visible)
// ---------------------------------------------------------------------------

class _RemoveButton extends ConsumerWidget {
  const _RemoveButton({
    required this.listId,
    required this.viewModel,
  });

  final String listId;
  final MapPickerViewModel viewModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<TodoList?>(
      future: ref.read(todoListRepositoryProvider).getListById(listId),
      builder: (context, snapshot) {
        final hasGeofence = snapshot.data?.geofenceId != null;
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
      },
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
