import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:whileyoureout/providers/providers.dart';
import 'package:whileyoureout/router/app_router.dart';

// ---------------------------------------------------------------------------
// Provider: single geofence region by ID
// ---------------------------------------------------------------------------

/// Fetches a [GeofenceRegion] by ID from the repository.
final _geofenceRegionProvider =
    FutureProvider.autoDispose.family<GeofenceRegion?, String>(
  (ref, geofenceId) =>
      ref.watch(geofenceRepositoryProvider).getGeofenceById(geofenceId),
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Displays the geofence details for a todo list and allows editing or
/// removing the location.
///
/// Route: `/list/:listId/location`
class LocationDetailScreen extends ConsumerStatefulWidget {
  /// Creates a [LocationDetailScreen] for the list identified by [listId].
  const LocationDetailScreen({required this.listId, super.key});

  /// The ID of the [TodoList] whose location details are shown.
  final String listId;

  @override
  ConsumerState<LocationDetailScreen> createState() =>
      _LocationDetailScreenState();
}

class _LocationDetailScreenState extends ConsumerState<LocationDetailScreen> {
  final Completer<gm.GoogleMapController> _mapCompleter = Completer();
  final TextEditingController _labelController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  /// Persists [notifyOnEnter] / [notifyOnExit] changes to the repository.
  Future<void> _saveListField(
    TodoList list, {
    bool? notifyOnEnter,
    bool? notifyOnExit,
  }) async {
    final updated = list.copyWith(
      notifyOnEnter: notifyOnEnter ?? list.notifyOnEnter,
      notifyOnExit: notifyOnExit ?? list.notifyOnExit,
    );
    await ref.read(todoListRepositoryProvider).saveList(updated);
  }

  /// Removes the geofence from the list and unregisters it with the OS.
  Future<void> _removeLocation(TodoList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove location?'),
        content: const Text(
          'The geofence will be deleted and arrival reminders disabled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      if (list.geofenceId != null) {
        await ref
            .read(unregisterGeofenceUseCaseProvider)
            .call(list.geofenceId!);
      }
      final cleared = list.copyWith(geofenceId: null);
      await ref.read(todoListRepositoryProvider).saveList(cleared);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(listByIdProvider(widget.listId));

    return Scaffold(
      appBar: AppBar(title: const Text('Location')),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list == null) {
            return const Center(child: Text('List not found'));
          }
          if (list.geofenceId == null) {
            return const Center(child: Text('No location set'));
          }
          return _LocationDetailBody(
            listId: widget.listId,
            list: list,
            mapCompleter: _mapCompleter,
            labelController: _labelController,
            isSaving: _isSaving,
            onNotifyEnterChanged: (val) =>
                _saveListField(list, notifyOnEnter: val),
            onNotifyExitChanged: (val) =>
                _saveListField(list, notifyOnExit: val),
            onEditLocation: () =>
                context.push(AppRoutes.mapPickerPath(widget.listId)),
            onRemoveLocation: () => _removeLocation(list),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _LocationDetailBody extends ConsumerWidget {
  const _LocationDetailBody({
    required this.listId,
    required this.list,
    required this.mapCompleter,
    required this.labelController,
    required this.isSaving,
    required this.onNotifyEnterChanged,
    required this.onNotifyExitChanged,
    required this.onEditLocation,
    required this.onRemoveLocation,
  });

  final String listId;
  final TodoList list;
  final Completer<gm.GoogleMapController> mapCompleter;
  final TextEditingController labelController;
  final bool isSaving;
  final ValueChanged<bool> onNotifyEnterChanged;
  final ValueChanged<bool> onNotifyExitChanged;
  final VoidCallback onEditLocation;
  final VoidCallback onRemoveLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final geofenceAsync = ref.watch(
      _geofenceRegionProvider(list.geofenceId!),
    );

    return geofenceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading geofence: $e')),
      data: (region) {
        if (region == null) {
          return const Center(child: Text('Geofence not found'));
        }

        // Populate label controller on first render.
        if (labelController.text.isEmpty && region.label.isNotEmpty) {
          labelController.text = region.label;
        }

        final theme = Theme.of(context);
        final radiusLabel =
            '${region.radiusMeters.toStringAsFixed(0)} m radius';

        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // ---------------------------------------------------------------
            // Map thumbnail (non-interactive)
            // ---------------------------------------------------------------
            SizedBox(
              height: 200,
              child: _MapThumbnail(
                region: region,
                mapCompleter: mapCompleter,
              ),
            ),

            const SizedBox(height: 16),

            // ---------------------------------------------------------------
            // Geofence label
            // ---------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: labelController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Location name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ---------------------------------------------------------------
            // Radius summary (read-only)
            // ---------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                radiusLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),

            const Divider(height: 32),

            // ---------------------------------------------------------------
            // Notification toggles
            // ---------------------------------------------------------------
            SwitchListTile(
              title: const Text('Notify on arrival'),
              subtitle: const Text('Alert when you enter this area'),
              value: list.notifyOnEnter,
              onChanged: onNotifyEnterChanged,
            ),
            SwitchListTile(
              title: const Text('Notify on departure'),
              subtitle: const Text('Alert when you leave this area'),
              value: list.notifyOnExit,
              onChanged: onNotifyExitChanged,
            ),

            const Divider(height: 32),

            // ---------------------------------------------------------------
            // Action buttons
            // ---------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: isSaving ? null : onEditLocation,
                    icon: const Icon(Icons.edit_location_alt_outlined),
                    label: const Text('Edit Location'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: isSaving ? null : onRemoveLocation,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    icon: const Icon(Icons.location_off_outlined),
                    label: const Text('Remove Location'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Map thumbnail (non-interactive)
// ---------------------------------------------------------------------------

class _MapThumbnail extends StatelessWidget {
  const _MapThumbnail({
    required this.region,
    required this.mapCompleter,
  });

  final GeofenceRegion region;
  final Completer<gm.GoogleMapController> mapCompleter;

  @override
  Widget build(BuildContext context) {
    final center = gm.LatLng(region.latitude, region.longitude);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return gm.GoogleMap(
      initialCameraPosition: gm.CameraPosition(
        target: center,
        zoom: 15,
      ),
      onMapCreated: (controller) {
        if (!mapCompleter.isCompleted) mapCompleter.complete(controller);
      },
      // Disable all gestures to make the map purely decorative/informational.
      zoomGesturesEnabled: false,
      scrollGesturesEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      liteModeEnabled: true,
      circles: {
        gm.Circle(
          circleId: const gm.CircleId('geofence'),
          center: center,
          radius: region.radiusMeters,
          fillColor: primaryColor.withValues(alpha: 0.15),
          strokeColor: primaryColor,
          strokeWidth: 2,
        ),
      },
      markers: {
        gm.Marker(
          markerId: const gm.MarkerId('pin'),
          position: center,
        ),
      },
    );
  }
}
