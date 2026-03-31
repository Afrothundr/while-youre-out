import 'package:domain/src/entities/todo_item.dart';
import 'package:domain/src/repositories/todo_item_repository.dart';

/// Toggles the [TodoItem.isDone] flag on a single item.
class ToggleItemUseCase {
  /// Creates a [ToggleItemUseCase].
  const ToggleItemUseCase(this._repository);

  final TodoItemRepository _repository;

  /// Flips the [TodoItem.isDone] flag for the item identified by [itemId].
  ///
  /// Returns the updated [TodoItem] after persisting the change.
  /// Returns `null` if no item with [itemId] exists.
  Future<TodoItem?> call(String itemId) async {
    final item = await _repository.getItemById(itemId);
    if (item == null) return null;

    final updated = item.copyWith(isDone: !item.isDone);
    await _repository.saveItem(updated);
    return updated;
  }
}
