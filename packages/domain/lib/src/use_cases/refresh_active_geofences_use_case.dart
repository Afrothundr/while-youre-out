import 'dart:math';

import 'package:domain/src/repositories/geofence_repository.dart';
import 'package:domain/src/services/geofence_service.dart';

/// Refreshes the set of OS-registered geofences to the 20 nearest active
/// regions, unregistering any that fall outside that window.
///
/// Most mobile OS geofence APIs cap the number of simultaneously monitored
/// regions (iOS: 20, Android: 100).  This use case enforces the conservative
/// limit of 20 so the app behaves correctly on all platforms.
class RefreshActiveGeofencesUseCase {
  /// Creates a [RefreshActiveGeofencesUseCase].
  const RefreshActiveGeofencesUseCase(
    this._geofenceRepository,
    this._geofenceService,
  );

  final GeofenceRepository _geofenceRepository;
  final GeofenceService _geofenceService;

  /// Maximum number of regions that may be simultaneously registered with the
  /// OS geofence monitor.
  static const int _maxRegistered = 20;

  /// Re-evaluates which geofences should be actively monitored based on
  /// proximity to the device's current position ([currentLat], [currentLng]).
  ///
  /// The [_maxRegistered] nearest regions are (re-)registered with the OS.
  /// Any regions beyond that window are unregistered and marked inactive in
  /// the repository.
  Future<void> call({
    required double currentLat,
    required double currentLng,
  }) async {
    final regions = await _geofenceRepository.getAllActiveGeofences();

    // Sort ascending by distance from the current position.
    final sorted = [...regions]..sort((a, b) {
        final distA = _haversineDistance(
          currentLat,
          currentLng,
          a.latitude,
          a.longitude,
        );
        final distB = _haversineDistance(
          currentLat,
          currentLng,
          b.latitude,
          b.longitude,
        );
        return distA.compareTo(distB);
      });

    final toRegister = sorted.take(_maxRegistered).toList();
    final toUnregister = sorted.skip(_maxRegistered).toList();

    await Future.wait([
      for (final region in toRegister)
        _geofenceService.registerRegion(region),
      for (final region in toUnregister) ...[
        _geofenceService.unregisterRegion(region.id),
        _geofenceRepository.setGeofenceActive(region.id, active: false),
      ],
    ]);
  }

  /// Calculates the great-circle distance in metres between two WGS-84
  /// coordinates using the Haversine formula.
  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6372800.0;

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;
}
