import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// View-model for the map picker screen.
///
/// Holds the user's selected pin location, radius, and label. Coordinates
/// calls to [AssignLocationUseCase], [RegisterGeofenceUseCase], and
/// [UnregisterGeofenceUseCase].
class MapPickerViewModel extends ChangeNotifier {
  /// The pin the user tapped on the map, or `null` if none placed yet.
  LatLng? selectedLatLng;

  /// Radius of the geofence circle in metres. Defaults to 200 m.
  double radiusMeters = 200;

  /// Human-readable label for the location.
  String label = '';

  /// Whether an async save / remove operation is in progress.
  bool isSaving = false;

  /// Updates the selected location to [latLng] and notifies listeners.
  void selectLocation(LatLng latLng) {
    selectedLatLng = latLng;
    notifyListeners();
  }

  /// Updates the geofence radius to [meters] and notifies listeners.
  void updateRadius(double meters) {
    radiusMeters = meters;
    notifyListeners();
  }

  /// Updates the label to [value] and notifies listeners.
  void updateLabel(String value) {
    label = value;
    notifyListeners();
  }

  /// Pre-fills the view-model with values from an existing [GeofenceRegion].
  ///
  /// Called when the screen is opened for a list that already has a geofence
  /// so the user can edit the existing values instead of starting fresh.
  void prefill(GeofenceRegion region) {
    selectedLatLng = LatLng(region.latitude, region.longitude);
    radiusMeters = region.radiusMeters;
    label = region.label;
    notifyListeners();
  }

  /// Saves the selected location for the list identified by [listId].
  ///
  /// 1. Calls [assignLocation] to upsert the [GeofenceRegion] in the DB and
  ///    update the list's `geofenceId`.
  /// 2. Calls [registerGeofence] to register the region with the OS using the
  ///    current geofence service implementation.
  ///
  /// Does nothing if [selectedLatLng] is `null`.
  Future<void> saveLocation({
    required String listId,
    required AssignLocationUseCase assignLocation,
    required RegisterGeofenceUseCase registerGeofence,
    required TodoListRepository listRepo,
  }) async {
    if (selectedLatLng == null) return;

    isSaving = true;
    notifyListeners();

    try {
      // 1. Persist geofence + update list.geofenceId.
      await assignLocation(
        listId: listId,
        lat: selectedLatLng!.latitude,
        lng: selectedLatLng!.longitude,
        radiusMeters: radiusMeters,
        label: label,
      );

      // 2. Register with OS (stub in Phase 2).
      final list = await listRepo.getListById(listId);
      if (list?.geofenceId != null) {
        await registerGeofence(list!.geofenceId!);
      }
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Removes the location assignment from the list identified by [listId].
  ///
  /// 1. Calls [unregisterGeofence] to unregister from the OS and set
  ///    `isActive = false` in the DB.
  /// 2. Clears `geofenceId` on the list record.
  ///
  /// Does nothing if the list has no geofence.
  Future<void> removeLocation({
    required String listId,
    required TodoListRepository listRepo,
    required GeofenceRepository geofenceRepo,
    required UnregisterGeofenceUseCase unregisterGeofence,
  }) async {
    final list = await listRepo.getListById(listId);
    if (list?.geofenceId == null) return;

    isSaving = true;
    notifyListeners();

    try {
      // 1. Unregister from OS + mark inactive in DB.
      await unregisterGeofence(list!.geofenceId!);

      // 2. Clear geofenceId on the list.
      await listRepo.saveList(list.copyWith(geofenceId: null));
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
