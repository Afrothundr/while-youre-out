import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whileyoureout/providers/providers.dart';
import 'package:whileyoureout/screens/map_picker/map_picker_bottom_sheet.dart';
import 'package:whileyoureout/screens/map_picker/map_picker_view_model.dart';
import 'package:whileyoureout/screens/map_picker/search_bar_with_suggestions.dart';
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
      if (permission == LocationPermission.deniedForever) {
        if (mounted) _showPermanentlyDeniedDialog();
        return;
      }
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          if (mounted) _showPermanentlyDeniedDialog();
          return;
        }
      }
      if (permission == LocationPermission.denied) {
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
        // If a suggestion was found, move the camera to it and place the pin.
        final vm = ref.read(_mapPickerViewModelProvider(widget.listId));
        if (vm.autoSuggestion != null && mounted) {
          final suggestedLatLng = LatLng(
            vm.autoSuggestion!.latitude,
            vm.autoSuggestion!.longitude,
          );
          _moveTo(suggestedLatLng);
          vm.selectLocation(suggestedLatLng);
        }
      }
    } catch (_) {
      // Auto-suggest is best-effort; never crash _initMap over it.
    }
  }

  /// Shows a dialog explaining that location access is permanently denied and
  /// offering to open the app's system settings page.
  void _showPermanentlyDeniedDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Location permission required'),
        content: const Text(
          'Please enable location access in your device Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
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
    final topPadding = MediaQuery.of(context).padding.top;

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
            onMapTapped: (gm.LatLng latLng) {
              viewModel
                ..clearAutocompleteSuggestions()
                ..tryAutoFillLabel(
                  lat: latLng.latitude,
                  lng: latLng.longitude,
                  service: ref.read(placesAutocompleteServiceProvider),
                );
            },
          ),

          // ----------------------------------------------------------------
          // Back button
          // ----------------------------------------------------------------
          Positioned(
            top: topPadding + 8,
            left: 8,
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

          // ----------------------------------------------------------------
          // Search bar (user-driven autocomplete) — positioned to the right
          // of the back button in the same row
          // ----------------------------------------------------------------
          Positioned(
            top: topPadding + 8,
            left: 64,
            right: 8,
            child: SearchBarWithSuggestions(
              viewModel: viewModel,
              locationBias: _center,
              onMoveCamera: _moveTo,
            ),
          ),

          // ----------------------------------------------------------------
          // Auto-suggest card — shown when Places API found a nearby match
          // and the user has not opened the manual search dropdown
          // ----------------------------------------------------------------
          if (viewModel.autoSuggestion != null &&
              viewModel.autocompleteSuggestions.isEmpty)
            Positioned(
              top: topPadding + 64,
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
          MapPickerBottomSheet(
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
    required this.onMapTapped,
  });

  final LatLng center;
  final Completer<gm.GoogleMapController> mapControllerCompleter;
  final MapPickerViewModel viewModel;
  final VoidCallback onMapReady;
  final ValueChanged<gm.LatLng> onMapTapped;

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
      onTap: (gm.LatLng latLng) {
        viewModel.selectLocation(
          LatLng(latLng.latitude, latLng.longitude),
        );
        onMapTapped(latLng);
      },
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
// Suggestion card (auto-suggest on open)
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
