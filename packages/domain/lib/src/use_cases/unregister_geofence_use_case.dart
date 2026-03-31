import 'package:domain/src/repositories/geofence_repository.dart';
import 'package:domain/src/services/geofence_service.dart';

/// Unregisters a geofence region from the OS geofence monitor and marks it
/// as inactive in the repository.
class UnregisterGeofenceUseCase {
  /// Creates an [UnregisterGeofenceUseCase].
  const UnregisterGeofenceUseCase(
    this._geofenceRepository,
    this._geofenceService,
  );

  final GeofenceRepository _geofenceRepository;
  final GeofenceService _geofenceService;

  /// Unregisters the region identified by [geofenceId] from the OS monitor.
  ///
  /// After the OS call succeeds the region's active flag is set to `false`
  /// in the repository. Does nothing if no region with that ID exists.
  Future<void> call(String geofenceId) async {
    final region = await _geofenceRepository.getGeofenceById(geofenceId);
    if (region == null) return;

    await _geofenceService.unregisterRegion(geofenceId);
    await _geofenceRepository.setGeofenceActive(geofenceId, active: false);
  }
}
