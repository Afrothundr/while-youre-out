import 'package:domain/src/entities/todo_item.dart';

/// Abstract repository for persisting and retrieving [TodoItem] records.
abstract class TodoItemRepository {
  /// Returns all items belonging to [listId].
  Future<List<TodoItem>> getItemsForList(String listId);

  /// A stream that emits the full list of [TodoItem]s for [listId] whenever
  /// data changes.
  ///
  /// Intended for use by reactive UI layers.
  Stream<List<TodoItem>> watchItemsForList(String listId);

  /// Returns the item with the given [id], or `null` if not found.
  ///
  /// Used by the toggle-item use case to fetch the item before flipping its
  /// state.
  Future<TodoItem?> getItemById(String id);

  /// Inserts or updates the given [item].
  Future<void> saveItem(TodoItem item);

  /// Permanently deletes the item identified by [id].
  Future<void> deleteItem(String id);

  /// Returns the number of incomplete (not done) items in [listId].
  ///
  /// Used to populate the dashboard badge count.
  Future<int> countIncompleteItems(String listId);
}
