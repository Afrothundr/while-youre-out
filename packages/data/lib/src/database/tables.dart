import 'package:drift/drift.dart';

/// Drift table definition for the `todo_lists` table.
class TodoListsTable extends Table {
  @override
  String get tableName => 'todo_lists';

  /// Primary key — UUID string.
  TextColumn get id => text()();

  /// Display title of the list.
  TextColumn get title => text()();

  /// ARGB integer colour value.
  IntColumn get color => integer().withDefault(const Constant(0xFF2196F3))();

  /// Whether to notify on geofence entry.
  BoolColumn get notifyOnEnter => boolean().withDefault(const Constant(true))();

  /// Whether to notify on geofence exit.
  BoolColumn get notifyOnExit => boolean().withDefault(const Constant(false))();

  /// Optional FK to a geofence region.
  TextColumn get geofenceId => text().nullable()();

  /// Zero-based sort position among all lists.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// When this list was first created.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Drift table definition for the `todo_items` table.
class TodoItemsTable extends Table {
  @override
  String get tableName => 'todo_items';

  /// Primary key — UUID string.
  TextColumn get id => text()();

  /// FK to the owning list — cascades on delete.
  TextColumn get listId =>
      text().references(TodoListsTable, #id, onDelete: KeyAction.cascade)();

  /// Display title of the item.
  TextColumn get title => text()();

  /// Optional extended notes.
  TextColumn get notes => text().nullable()();

  /// Whether this item has been completed.
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();

  /// Optional due date.
  DateTimeColumn get dueDate => dateTime().nullable()();

  /// Priority level: 0 = none, 1 = low, 2 = medium, 3 = high.
  IntColumn get priority => integer().withDefault(const Constant(0))();

  /// When this item was first created.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Drift table definition for the `geofence_regions` table.
class GeofenceRegionsTable extends Table {
  @override
  String get tableName => 'geofence_regions';

  /// Primary key — UUID string.
  TextColumn get id => text()();

  /// Latitude of the region centre, in degrees.
  RealColumn get latitude => real()();

  /// Longitude of the region centre, in degrees.
  RealColumn get longitude => real()();

  /// Radius of the region in metres.
  RealColumn get radiusMeters => real()();

  /// Human-readable label for this region.
  TextColumn get label => text().withDefault(const Constant(''))();

  /// Whether this region is currently registered with the OS.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Which transition(s) cause this region to fire ('enter', 'exit',
  /// 'enterAndExit').
  TextColumn get trigger =>
      text().withDefault(const Constant('enter'))();

  /// When this region was first created.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
