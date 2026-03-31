import 'package:data/src/database/app_database.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

/// Converts a drift [GeofenceRegionsTableData] row to a domain
/// [GeofenceRegion].
extension GeofenceRegionRowMapper on GeofenceRegionsTableData {
  /// Maps this drift row to its domain representation.
  GeofenceRegion toDomain() => GeofenceRegion(
        id: id,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        label: label,
        isActive: isActive,
        trigger: _triggerFromString(trigger),
        createdAt: createdAt,
      );
}

/// Converts a domain [GeofenceRegion] to a drift
/// [GeofenceRegionsTableCompanion].
extension GeofenceRegionDomainMapper on GeofenceRegion {
  /// Maps this domain entity to a drift companion suitable for insert/update.
  GeofenceRegionsTableCompanion toCompanion() =>
      GeofenceRegionsTableCompanion(
        id: Value(id),
        latitude: Value(latitude),
        longitude: Value(longitude),
        radiusMeters: Value(radiusMeters),
        label: Value(label),
        isActive: Value(isActive),
        trigger: Value(_triggerToString(trigger)),
        createdAt: Value(createdAt),
      );
}

/// Maps a stored trigger string to the [GeofenceTrigger] enum.
GeofenceTrigger _triggerFromString(String value) {
  switch (value) {
    case 'exit':
      return GeofenceTrigger.exit;
    case 'enterAndExit':
      return GeofenceTrigger.enterAndExit;
    case 'enter':
    default:
      return GeofenceTrigger.enter;
  }
}

/// Maps a [GeofenceTrigger] enum value to its stored string representation.
String _triggerToString(GeofenceTrigger trigger) {
  switch (trigger) {
    case GeofenceTrigger.exit:
      return 'exit';
    case GeofenceTrigger.enterAndExit:
      return 'enterAndExit';
    case GeofenceTrigger.enter:
      return 'enter';
  }
}
