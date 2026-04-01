import 'dart:async';
import 'dart:io';

import 'package:domain/domain.dart';
import 'package:geolocator/geolocator.dart';

/// Manages the iOS priority-queue region-swap strategy.
///
/// iOS limits active geofence regions to 20. [GeofenceManager] listens to
/// low-accuracy position updates and calls [RefreshActiveGeofencesUseCase]
/// every 500 m of movement to keep the 20 nearest regions registered.
///
/// On Android all 100 regions may be registered at once, so this manager
/// is a no-op on that platform.
class GeofenceManager {
  /// Creates a [GeofenceManager].
  GeofenceManager({
    required this.geofenceService,
    required this.refreshActiveGeofences,
  });

  /// The OS-level geofence service (used for internal wiring, not directly
  /// called by this class — [refreshActiveGeofences] handles registration).
  final GeofenceService geofenceService;

  /// Use case that re-evaluates which 20 regions should be active.
  final RefreshActiveGeofencesUseCase refreshActiveGeofences;

  StreamSubscription<Position>? _locationSub;

  /// Starts the position listener.
  ///
  /// Call once after DI is set up. Safe to call multiple times — subsequent
  /// calls are no-ops if already started.
  void start() {
    // Android supports up to 100 simultaneous geofences; no swapping needed.
    if (!Platform.isIOS) return;
    if (_locationSub != null) return;

    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: 500,
      ),
    ).handleError((_) {
      // Swallow location errors (e.g. kCLErrorLocationUnknown in the iOS
      // Simulator). The stream remains open and will emit positions once
      // the device/simulator acquires a fix.
    }).listen((position) async {
      await refreshActiveGeofences(
        currentLat: position.latitude,
        currentLng: position.longitude,
      );
    });
  }

  /// Cancels the position listener and frees resources.
  void dispose() {
    _locationSub?.cancel();
    _locationSub = null;
  }
}
