import 'package:domain/src/entities/geofence_region.dart';

/// Abstract repository for persisting and retrieving [GeofenceRegion] records.
abstract class GeofenceRepository {
  /// Returns the region with the given [id], or `null` if not found.
  Future<GeofenceRegion?> getGeofenceById(String id);

  /// Returns all regions that are currently marked as active.
  Future<List<GeofenceRegion>> getAllActiveGeofences();

  /// Inserts or updates the given [region].
  Future<void> saveGeofence(GeofenceRegion region);

  /// Permanently deletes the region identified by [id].
  Future<void> deleteGeofence(String id);

  /// Sets the active flag on the region identified by [id].
  ///
  /// Used by refresh and unregister use cases to keep the persisted state
  /// in sync with what is registered with the OS.
  Future<void> setGeofenceActive(String id, {required bool active});
}
