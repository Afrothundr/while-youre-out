import 'package:equatable/equatable.dart';

/// The condition(s) under which a geofence fires.
enum GeofenceTrigger {
  /// Fire when the device enters the region.
  enter,

  /// Fire when the device exits the region.
  exit,

  /// Fire on both entry and exit.
  enterAndExit,
}

/// The type of a geofence event.
enum GeofenceEventType {
  /// The device entered the region.
  enter,

  /// The device exited the region.
  exit,
}

/// A circular geographic region used to trigger notifications.
class GeofenceRegion extends Equatable {
  /// Creates a [GeofenceRegion].
  const GeofenceRegion({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.createdAt,
    this.label = '',
    this.isActive = false,
    this.trigger = GeofenceTrigger.enter,
  });

  /// Unique identifier (UUID v4).
  final String id;

  /// Latitude of the region centre, in degrees.
  final double latitude;

  /// Longitude of the region centre, in degrees.
  final double longitude;

  /// Radius of the region in metres.
  ///
  /// The minimum value is enforced at use-case level: 100 m.
  final double radiusMeters;

  /// When this region was first created.
  final DateTime createdAt;

  /// Human-readable label for this region (e.g. "Home", "Supermarket").
  final String label;

  /// Whether this region is currently registered with the OS geofence service.
  final bool isActive;

  /// Which transition(s) cause this region to fire.
  final GeofenceTrigger trigger;

  /// Returns a copy of this [GeofenceRegion] with the given fields replaced.
  GeofenceRegion copyWith({
    String? id,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    DateTime? createdAt,
    String? label,
    bool? isActive,
    GeofenceTrigger? trigger,
  }) {
    return GeofenceRegion(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      createdAt: createdAt ?? this.createdAt,
      label: label ?? this.label,
      isActive: isActive ?? this.isActive,
      trigger: trigger ?? this.trigger,
    );
  }

  @override
  List<Object?> get props => [
        id,
        latitude,
        longitude,
        radiusMeters,
        createdAt,
        label,
        isActive,
        trigger,
      ];
}

/// An event fired by the OS when the device crosses a geofence boundary.
class GeofenceEvent extends Equatable {
  /// Creates a [GeofenceEvent].
  const GeofenceEvent({
    required this.regionId,
    required this.type,
    required this.timestamp,
  });

  /// The ID of the geofence region that was crossed.
  final String regionId;

  /// Whether this was an entry or exit event.
  final GeofenceEventType type;

  /// When the boundary crossing was detected.
  final DateTime timestamp;

  @override
  List<Object?> get props => [regionId, type, timestamp];
}
