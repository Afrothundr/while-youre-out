import 'dart:io';

import 'package:data/src/database/tables.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// The application's drift database.
///
/// Tables: [TodoListsTable], [TodoItemsTable], [GeofenceRegionsTable].
@DriftDatabase(
  tables: [TodoListsTable, TodoItemsTable, GeofenceRegionsTable],
)
class AppDatabase extends _$AppDatabase {
  /// Creates the production database backed by a file on disk.
  AppDatabase({Future<void> Function(String path)? onFileReady})
      : super(_openConnection(onFileReady: onFileReady));

  /// Creates an in-memory database suitable for unit tests.
  ///
  /// ```dart
  /// final db = AppDatabase.forTesting(NativeDatabase.memory());
  /// ```
  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          // Enable FK enforcement for this connection.
          await customStatement('PRAGMA foreign_keys = ON');
          await m.createAll();
          // Composite index for fast incomplete-item counts and list queries.
          await customStatement(
            'CREATE INDEX idx_todo_items_list_done '
            'ON todo_items(list_id, is_done)',
          );
        },
        beforeOpen: (details) async {
          // Re-apply FK pragma on every open (persists per-connection).
          await customStatement('PRAGMA foreign_keys = ON');
        },
        onUpgrade: (m, from, to) async {
          // Add future migrations here.
        },
      );
}

/// Opens a lazy, file-backed [DatabaseConnection] for production use.
///
/// The optional [onFileReady] callback is called with the resolved database
/// file path immediately before the connection is opened. The app shell uses
/// this to exclude the file from iCloud backup (iOS only).
LazyDatabase _openConnection({
  Future<void> Function(String path)? onFileReady,
}) {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'while_youre_out.db'));

    await onFileReady?.call(file.path);

    return NativeDatabase.createInBackground(file);
  });
}
