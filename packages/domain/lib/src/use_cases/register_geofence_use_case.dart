import 'package:domain/src/repositories/geofence_repository.dart';
import 'package:domain/src/services/geofence_service.dart';

/// Registers an existing geofence region with the OS geofence monitor and
/// marks it as active in the repository.
class RegisterGeofenceUseCase {
  /// Creates a [RegisterGeofenceUseCase].
  const RegisterGeofenceUseCase(
    this._geofenceRepository,
    this._geofenceService,
  );

  final GeofenceRepository _geofenceRepository;
  final GeofenceService _geofenceService;

  /// Registers the region identified by [geofenceId] with the OS monitor.
  ///
  /// Does nothing if no region with that ID exists in the repository.
  /// After successful registration the region's active flag is set to `true`
  /// in the repository.
  Future<void> call(String geofenceId) async {
    final region = await _geofenceRepository.getGeofenceById(geofenceId);
    if (region == null) return;

    await _geofenceService.registerRegion(region);
    await _geofenceRepository.setGeofenceActive(geofenceId, active: true);
  }
}
