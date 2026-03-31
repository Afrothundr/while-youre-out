import 'package:data/src/database/app_database.dart';
import 'package:data/src/mappers/geofence_region_mapper.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

/// Drift-backed implementation of [GeofenceRepository].
class DriftGeofenceRepository implements GeofenceRepository {
  /// Creates a [DriftGeofenceRepository] backed by the given [_db].
  const DriftGeofenceRepository(this._db);

  final AppDatabase _db;

  @override
  Future<GeofenceRegion?> getGeofenceById(String id) async {
    final row = await (_db.select(_db.geofenceRegionsTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<List<GeofenceRegion>> getAllActiveGeofences() async {
    final rows = await (_db.select(_db.geofenceRegionsTable)
          ..where((t) => t.isActive.equals(true)))
        .get();
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<void> saveGeofence(GeofenceRegion region) async {
    await _db
        .into(_db.geofenceRegionsTable)
        .insertOnConflictUpdate(region.toCompanion());
  }

  @override
  Future<void> deleteGeofence(String id) async {
    await (_db.delete(_db.geofenceRegionsTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  @override
  Future<void> setGeofenceActive(String id, {required bool active}) async {
    await (_db.update(_db.geofenceRegionsTable)
          ..where((t) => t.id.equals(id)))
        .write(GeofenceRegionsTableCompanion(isActive: Value(active)));
  }
}
