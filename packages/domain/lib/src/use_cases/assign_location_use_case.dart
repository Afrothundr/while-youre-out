import 'package:domain/src/entities/geofence_region.dart';
import 'package:domain/src/repositories/geofence_repository.dart';
import 'package:domain/src/repositories/todo_list_repository.dart';
import 'package:uuid/uuid.dart';

/// Assigns (or replaces) a geographic location on a todo list.
///
/// If the list already has a geofence ID, the existing region record is
/// overwritten in-place (same ID).  Otherwise a new region is created with
/// a fresh UUID and the list is updated to reference it.
class AssignLocationUseCase {
  /// Creates an [AssignLocationUseCase].
  const AssignLocationUseCase(
    this._listRepository,
    this._geofenceRepository,
  );

  final TodoListRepository _listRepository;
  final GeofenceRepository _geofenceRepository;

  /// Assigns a location to the list identified by [listId].
  ///
  /// [lat] and [lng] are the WGS-84 coordinates of the region centre.
  /// [radiusMeters] is the radius of the circular region; the minimum
  /// enforced value is 100 m.
  /// [label] is an optional human-readable name for the location.
  Future<void> call({
    required String listId,
    required double lat,
    required double lng,
    required double radiusMeters,
    String label = '',
  }) async {
    final list = await _listRepository.getListById(listId);
    if (list == null) return;

    final effectiveRadius = radiusMeters < 100 ? 100.0 : radiusMeters;

    final regionId = list.geofenceId ?? const Uuid().v4();

    final region = GeofenceRegion(
      id: regionId,
      latitude: lat,
      longitude: lng,
      radiusMeters: effectiveRadius,
      label: label,
      createdAt: DateTime.now(),
    );

    await _geofenceRepository.saveGeofence(region);

    if (list.geofenceId == null) {
      final updated = list.copyWith(geofenceId: regionId);
      await _listRepository.saveList(updated);
    }
  }
}
