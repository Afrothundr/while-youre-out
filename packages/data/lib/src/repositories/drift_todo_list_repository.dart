import 'package:data/src/database/app_database.dart';
import 'package:data/src/mappers/todo_list_mapper.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

/// Drift-backed implementation of [TodoListRepository].
class DriftTodoListRepository implements TodoListRepository {
  /// Creates a [DriftTodoListRepository] backed by the given [_db].
  const DriftTodoListRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<TodoList>> getAllLists() async {
    final rows = await (_db.select(_db.todoListsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Stream<List<TodoList>> watchAllLists() {
    return (_db.select(_db.todoListsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch()
        .map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  @override
  Future<TodoList?> getListById(String id) async {
    final row = await (_db.select(_db.todoListsTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<TodoList?> getListByGeofenceId(String geofenceId) async {
    final row = await (_db.select(_db.todoListsTable)
          ..where((t) => t.geofenceId.equals(geofenceId)))
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<void> saveList(TodoList list) async {
    await _db
        .into(_db.todoListsTable)
        .insertOnConflictUpdate(list.toCompanion());
  }

  @override
  Future<void> deleteList(String id) async {
    await (_db.delete(_db.todoListsTable)..where((t) => t.id.equals(id))).go();
  }
}
