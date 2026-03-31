import 'package:domain/domain.dart';

/// A stub implementation of [GeofenceService] used during Phase 2 development.
///
/// All methods are no-ops or log to the console — no real OS geofencing calls
/// are made. Replace with the real platform bridge in Phase 3.
class StubGeofenceService implements GeofenceService {
  @override
  Future<void> registerRegion(GeofenceRegion region) async {
    // ignore: avoid_print
    print(
      '[StubGeofenceService] registerRegion: ${region.id} @ '
      '${region.latitude},${region.longitude}',
    );
  }

  @override
  Future<void> unregisterRegion(String regionId) async {
    // ignore: avoid_print
    print('[StubGeofenceService] unregisterRegion: $regionId');
  }

  @override
  Future<void> unregisterAll() async {}

  @override
  Stream<GeofenceEvent> get events => const Stream.empty();
}
