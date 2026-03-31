import 'package:domain/src/repositories/geofence_repository.dart';
import 'package:domain/src/repositories/todo_item_repository.dart';
import 'package:domain/src/repositories/todo_list_repository.dart';
import 'package:domain/src/services/geofence_service.dart';

/// Deletes a todo list and all associated items and geofence data.
class DeleteListUseCase {
  /// Creates a [DeleteListUseCase].
  const DeleteListUseCase(
    this._listRepository,
    this._itemRepository,
    this._geofenceRepository,
    this._geofenceService,
  );

  final TodoListRepository _listRepository;
  final TodoItemRepository _itemRepository;
  final GeofenceRepository _geofenceRepository;
  final GeofenceService _geofenceService;

  /// Deletes the list identified by [listId], along with all of its items.
  ///
  /// If the list has an associated geofence, the region is first unregistered
  /// from the OS and then deleted from the repository before the list itself
  /// is removed.
  Future<void> call(String listId) async {
    final list = await _listRepository.getListById(listId);
    if (list == null) return;

    final geofenceId = list.geofenceId;
    if (geofenceId != null) {
      await _geofenceService.unregisterRegion(geofenceId);
      await _geofenceRepository.deleteGeofence(geofenceId);
    }

    final items = await _itemRepository.getItemsForList(listId);
    await Future.wait(items.map((item) => _itemRepository.deleteItem(item.id)));

    await _listRepository.deleteList(listId);
  }
}
