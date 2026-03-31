import 'package:domain/src/entities/todo_item.dart';
import 'package:domain/src/repositories/todo_item_repository.dart';
import 'package:uuid/uuid.dart';

/// Creates a new [TodoItem] and persists it in the repository.
class CreateItemUseCase {
  /// Creates a [CreateItemUseCase].
  const CreateItemUseCase(this._repository);

  final TodoItemRepository _repository;

  /// Creates and persists a new [TodoItem] belonging to [listId].
  ///
  /// [title] is the display text for the item.
  /// [notes] is an optional extended description.
  /// [priority] defaults to 0 (none); valid values are 0–3.
  ///
  /// Returns the newly created [TodoItem].
  Future<TodoItem> call({
    required String listId,
    required String title,
    String? notes,
    int priority = 0,
  }) async {
    final item = TodoItem(
      id: const Uuid().v4(),
      listId: listId,
      title: title,
      notes: notes,
      priority: priority,
      createdAt: DateTime.now(),
    );

    await _repository.saveItem(item);
    return item;
  }
}
