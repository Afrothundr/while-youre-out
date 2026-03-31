import 'package:domain/src/entities/todo_list.dart';
import 'package:domain/src/repositories/todo_list_repository.dart';
import 'package:uuid/uuid.dart';

/// Creates a new [TodoList] with a generated UUID and correct sort order.
class CreateListUseCase {
  /// Creates a [CreateListUseCase].
  const CreateListUseCase(this._repository);

  final TodoListRepository _repository;

  /// Creates and persists a new [TodoList] with the given [title] and [color].
  ///
  /// The new list's [TodoList.sortOrder] is set to
  /// `(max existing sortOrder) + 1` so that it appears at the bottom of the
  /// user's lists.
  Future<TodoList> call({
    required String title,
    int color = 0xFF2196F3,
  }) async {
    final existing = await _repository.getAllLists();
    final maxOrder = existing.isEmpty
        ? -1
        : existing
            .map((l) => l.sortOrder)
            .reduce((a, b) => a > b ? a : b);

    final list = TodoList(
      id: const Uuid().v4(),
      title: title,
      color: color,
      sortOrder: maxOrder + 1,
      createdAt: DateTime.now(),
    );

    await _repository.saveList(list);
    return list;
  }
}
