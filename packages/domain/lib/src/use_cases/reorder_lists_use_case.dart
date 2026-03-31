import 'package:domain/src/repositories/todo_list_repository.dart';

/// Reorders todo lists by assigning each a new sort order based on
/// the caller-supplied ordered list of IDs.
class ReorderListsUseCase {
  /// Creates a [ReorderListsUseCase].
  const ReorderListsUseCase(this._repository);

  final TodoListRepository _repository;

  /// Persists a new sort order for the lists identified by [orderedIds].
  ///
  /// Each list at index `i` in [orderedIds] will have its sort order set to
  /// `i`. Lists whose IDs are not found in the repository are silently
  /// skipped.
  Future<void> call(List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      final list = await _repository.getListById(orderedIds[i]);
      if (list == null) continue;
      await _repository.saveList(list.copyWith(sortOrder: i));
    }
  }
}
