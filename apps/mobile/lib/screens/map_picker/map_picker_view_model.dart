import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:whileyoureout/services/places_suggestion_service.dart';

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

  /// The auto-suggested place from the Places API, or null if none was found
  /// or the user dismissed the card.
  PlaceSuggestion? autoSuggestion;

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

  /// Queries [service] for a place matching [listTitle] near ([lat], [lng]).
  ///
  /// If a suggestion is found:
  /// - Sets [autoSuggestion].
  /// - Pre-fills [label] with the place name if [label] is still empty
  ///   (does not overwrite a label the user has already typed).
  /// - Notifies listeners.
  ///
  /// If [service] returns null (no match, key missing, or network error),
  /// this method is a no-op.
  Future<void> tryAutoSuggestLocation({
    required String listTitle,
    required double lat,
    required double lng,
    required PlacesSuggestionService service,
  }) async {
    final suggestion = await service.findNearbyPlace(
      keyword: listTitle,
      lat: lat,
      lng: lng,
    );
    if (suggestion != null) {
      autoSuggestion = suggestion;
      if (label.isEmpty) {
        label = suggestion.name;
      }
      notifyListeners();
    }
  }

  /// Clears [autoSuggestion] (called when the user dismisses the card).
  ///
  /// Does NOT clear [label] — the user may have already accepted the
  /// pre-filled label and started editing it.
  void dismissAutoSuggestion() {
    autoSuggestion = null;
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
