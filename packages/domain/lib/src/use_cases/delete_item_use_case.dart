import 'package:domain/src/repositories/todo_item_repository.dart';

/// Permanently deletes a todo item from the repository.
class DeleteItemUseCase {
  /// Creates a [DeleteItemUseCase].
  const DeleteItemUseCase(this._repository);

  final TodoItemRepository _repository;

  /// Deletes the item identified by [itemId].
  ///
  /// Does nothing if no item with [itemId] exists in the repository.
  Future<void> call(String itemId) async {
    await _repository.deleteItem(itemId);
  }
}
