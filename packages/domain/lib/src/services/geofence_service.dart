import 'package:domain/src/entities/geofence_region.dart';

/// Abstract OS-level geofence service. Implemented by the `geofencing` package.
abstract class GeofenceService {
  /// Registers [region] with the OS geofence monitor.
  ///
  /// If a region with the same [GeofenceRegion.id] is already registered it
  /// will be replaced.
  Future<void> registerRegion(GeofenceRegion region);

  /// Unregisters the region identified by [regionId] from the OS monitor.
  ///
  /// Does nothing if the region is not currently registered.
  Future<void> unregisterRegion(String regionId);

  /// Unregisters all regions currently monitored by this service.
  Future<void> unregisterAll();

  /// A stream of [GeofenceEvent]s emitted whenever the device crosses a
  /// registered region boundary.
  Stream<GeofenceEvent> get events;
}
