import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:whileyoureout/providers/providers.dart';
import 'package:whileyoureout/screens/map_picker/map_picker_view_model.dart';

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
  final MapController _mapController = MapController();
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
  }

  void _moveTo(LatLng latLng) {
    setState(() => _center = latLng);
    if (_mapReady) {
      _mapController.move(latLng, _kDefaultZoom);
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
            mapController: _mapController,
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
    required this.mapController,
    required this.viewModel,
    required this.onMapReady,
  });

  final LatLng center;
  final MapController mapController;
  final MapPickerViewModel viewModel;
  final VoidCallback onMapReady;

  @override
  Widget build(BuildContext context) {
    final pin = viewModel.selectedLatLng;

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: _kDefaultZoom,
        onMapReady: onMapReady,
        onTap: (_, latLng) => viewModel.selectLocation(latLng),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.whileyoureout.app',
        ),
        if (pin != null) ...[
          CircleLayer(
            circles: [
              CircleMarker(
                point: pin,
                radius: viewModel.radiusMeters,
                useRadiusInMeter: true,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15),
                borderColor: Theme.of(context).colorScheme.primary,
                borderStrokeWidth: 2,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: pin,
                width: 40,
                height: 40,
                child: Icon(
                  Icons.location_pin,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ],
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
  }

  @override
  void dispose() {
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
