import 'package:data/src/database/app_database.dart';
import 'package:data/src/mappers/todo_item_mapper.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

/// Drift-backed implementation of [TodoItemRepository].
class DriftTodoItemRepository implements TodoItemRepository {
  /// Creates a [DriftTodoItemRepository] backed by the given [_db].
  const DriftTodoItemRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<TodoItem>> getItemsForList(String listId) async {
    final rows = await (_db.select(_db.todoItemsTable)
          ..where((t) => t.listId.equals(listId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.priority),
            (t) => OrderingTerm.asc(t.isDone),
          ]))
        .get();
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Stream<List<TodoItem>> watchItemsForList(String listId) {
    return (_db.select(_db.todoItemsTable)
          ..where((t) => t.listId.equals(listId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.priority),
            (t) => OrderingTerm.asc(t.isDone),
          ]))
        .watch()
        .map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  @override
  Future<TodoItem?> getItemById(String id) async {
    final row = await (_db.select(_db.todoItemsTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<void> saveItem(TodoItem item) async {
    await _db
        .into(_db.todoItemsTable)
        .insertOnConflictUpdate(item.toCompanion());
  }

  @override
  Future<void> deleteItem(String id) async {
    await (_db.delete(_db.todoItemsTable)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<int> countIncompleteItems(String listId) async {
    final countExp = _db.todoItemsTable.id.count();
    final query = _db.selectOnly(_db.todoItemsTable)
      ..addColumns([countExp])
      ..where(
        _db.todoItemsTable.listId.equals(listId) &
            _db.todoItemsTable.isDone.equals(false),
      );
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }
}
