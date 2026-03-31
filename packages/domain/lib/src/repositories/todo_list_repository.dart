import 'package:domain/src/entities/todo_list.dart';

/// Abstract repository for persisting and retrieving [TodoList] records.
abstract class TodoListRepository {
  /// Returns all lists, ordered by [TodoList.sortOrder].
  Future<List<TodoList>> getAllLists();

  /// A stream that emits the full list of [TodoList]s whenever data changes.
  ///
  /// Intended for use by reactive UI layers.
  Stream<List<TodoList>> watchAllLists();

  /// Returns the list with the given [id], or `null` if not found.
  Future<TodoList?> getListById(String id);

  /// Returns the list whose [TodoList.geofenceId] matches [geofenceId], or
  /// `null` if no such list exists.
  ///
  /// Used by the handle-geofence-entry use case to resolve a region back to
  /// its list.
  Future<TodoList?> getListByGeofenceId(String geofenceId);

  /// Inserts or updates the given [list].
  Future<void> saveList(TodoList list);

  /// Permanently deletes the list identified by [id].
  Future<void> deleteList(String id);
}
