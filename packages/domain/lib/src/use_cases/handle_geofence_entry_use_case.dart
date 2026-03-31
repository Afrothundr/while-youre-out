import 'package:domain/src/repositories/todo_item_repository.dart';
import 'package:domain/src/repositories/todo_list_repository.dart';
import 'package:domain/src/services/notification_service.dart';

/// Handles a geofence entry event by posting a notification for the
/// associated todo list, if one exists.
class HandleGeofenceEntryUseCase {
  /// Creates a [HandleGeofenceEntryUseCase].
  const HandleGeofenceEntryUseCase(
    this._listRepository,
    this._itemRepository,
    this._notificationService,
  );

  final TodoListRepository _listRepository;
  final TodoItemRepository _itemRepository;
  final NotificationService _notificationService;

  /// Handles a geofence entry event for the region identified by [regionId].
  ///
  /// Looks up the todo list associated with [regionId]. If no list is found,
  /// returns early without posting a notification. Otherwise, counts the
  /// incomplete items on the list and posts a local notification.
  Future<void> call(String regionId) async {
    final list = await _listRepository.getListByGeofenceId(regionId);
    if (list == null) return;

    final incompleteCount =
        await _itemRepository.countIncompleteItems(list.id);

    await _notificationService.postListNotification(
      listId: list.id,
      listTitle: list.title,
      incompleteCount: incompleteCount,
    );
  }
}
