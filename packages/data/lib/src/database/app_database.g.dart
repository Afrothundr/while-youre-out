// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TodoListsTableTable extends TodoListsTable
    with TableInfo<$TodoListsTableTable, TodoListsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodoListsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
      'color', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0xFF2196F3));
  static const VerificationMeta _notifyOnEnterMeta =
      const VerificationMeta('notifyOnEnter');
  @override
  late final GeneratedColumn<bool> notifyOnEnter = GeneratedColumn<bool>(
      'notify_on_enter', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("notify_on_enter" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _notifyOnExitMeta =
      const VerificationMeta('notifyOnExit');
  @override
  late final GeneratedColumn<bool> notifyOnExit = GeneratedColumn<bool>(
      'notify_on_exit', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("notify_on_exit" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _geofenceIdMeta =
      const VerificationMeta('geofenceId');
  @override
  late final GeneratedColumn<String> geofenceId = GeneratedColumn<String>(
      'geofence_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        color,
        notifyOnEnter,
        notifyOnExit,
        geofenceId,
        sortOrder,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todo_lists';
  @override
  VerificationContext validateIntegrity(Insertable<TodoListsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('notify_on_enter')) {
      context.handle(
          _notifyOnEnterMeta,
          notifyOnEnter.isAcceptableOrUnknown(
              data['notify_on_enter']!, _notifyOnEnterMeta));
    }
    if (data.containsKey('notify_on_exit')) {
      context.handle(
          _notifyOnExitMeta,
          notifyOnExit.isAcceptableOrUnknown(
              data['notify_on_exit']!, _notifyOnExitMeta));
    }
    if (data.containsKey('geofence_id')) {
      context.handle(
          _geofenceIdMeta,
          geofenceId.isAcceptableOrUnknown(
              data['geofence_id']!, _geofenceIdMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TodoListsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TodoListsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color'])!,
      notifyOnEnter: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}notify_on_enter'])!,
      notifyOnExit: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}notify_on_exit'])!,
      geofenceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}geofence_id']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TodoListsTableTable createAlias(String alias) {
    return $TodoListsTableTable(attachedDatabase, alias);
  }
}

class TodoListsTableData extends DataClass
    implements Insertable<TodoListsTableData> {
  /// Primary key — UUID string.
  final String id;

  /// Display title of the list.
  final String title;

  /// ARGB integer colour value.
  final int color;

  /// Whether to notify on geofence entry.
  final bool notifyOnEnter;

  /// Whether to notify on geofence exit.
  final bool notifyOnExit;

  /// Optional FK to a geofence region.
  final String? geofenceId;

  /// Zero-based sort position among all lists.
  final int sortOrder;

  /// When this list was first created.
  final DateTime createdAt;
  const TodoListsTableData(
      {required this.id,
      required this.title,
      required this.color,
      required this.notifyOnEnter,
      required this.notifyOnExit,
      this.geofenceId,
      required this.sortOrder,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['color'] = Variable<int>(color);
    map['notify_on_enter'] = Variable<bool>(notifyOnEnter);
    map['notify_on_exit'] = Variable<bool>(notifyOnExit);
    if (!nullToAbsent || geofenceId != null) {
      map['geofence_id'] = Variable<String>(geofenceId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TodoListsTableCompanion toCompanion(bool nullToAbsent) {
    return TodoListsTableCompanion(
      id: Value(id),
      title: Value(title),
      color: Value(color),
      notifyOnEnter: Value(notifyOnEnter),
      notifyOnExit: Value(notifyOnExit),
      geofenceId: geofenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(geofenceId),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory TodoListsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoListsTableData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      color: serializer.fromJson<int>(json['color']),
      notifyOnEnter: serializer.fromJson<bool>(json['notifyOnEnter']),
      notifyOnExit: serializer.fromJson<bool>(json['notifyOnExit']),
      geofenceId: serializer.fromJson<String?>(json['geofenceId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'color': serializer.toJson<int>(color),
      'notifyOnEnter': serializer.toJson<bool>(notifyOnEnter),
      'notifyOnExit': serializer.toJson<bool>(notifyOnExit),
      'geofenceId': serializer.toJson<String?>(geofenceId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TodoListsTableData copyWith(
          {String? id,
          String? title,
          int? color,
          bool? notifyOnEnter,
          bool? notifyOnExit,
          Value<String?> geofenceId = const Value.absent(),
          int? sortOrder,
          DateTime? createdAt}) =>
      TodoListsTableData(
        id: id ?? this.id,
        title: title ?? this.title,
        color: color ?? this.color,
        notifyOnEnter: notifyOnEnter ?? this.notifyOnEnter,
        notifyOnExit: notifyOnExit ?? this.notifyOnExit,
        geofenceId: geofenceId.present ? geofenceId.value : this.geofenceId,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
      );
  TodoListsTableData copyWithCompanion(TodoListsTableCompanion data) {
    return TodoListsTableData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      color: data.color.present ? data.color.value : this.color,
      notifyOnEnter: data.notifyOnEnter.present
          ? data.notifyOnEnter.value
          : this.notifyOnEnter,
      notifyOnExit: data.notifyOnExit.present
          ? data.notifyOnExit.value
          : this.notifyOnExit,
      geofenceId:
          data.geofenceId.present ? data.geofenceId.value : this.geofenceId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TodoListsTableData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('color: $color, ')
          ..write('notifyOnEnter: $notifyOnEnter, ')
          ..write('notifyOnExit: $notifyOnExit, ')
          ..write('geofenceId: $geofenceId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, color, notifyOnEnter, notifyOnExit,
      geofenceId, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoListsTableData &&
          other.id == this.id &&
          other.title == this.title &&
          other.color == this.color &&
          other.notifyOnEnter == this.notifyOnEnter &&
          other.notifyOnExit == this.notifyOnExit &&
          other.geofenceId == this.geofenceId &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class TodoListsTableCompanion extends UpdateCompanion<TodoListsTableData> {
  final Value<String> id;
  final Value<String> title;
  final Value<int> color;
  final Value<bool> notifyOnEnter;
  final Value<bool> notifyOnExit;
  final Value<String?> geofenceId;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TodoListsTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.color = const Value.absent(),
    this.notifyOnEnter = const Value.absent(),
    this.notifyOnExit = const Value.absent(),
    this.geofenceId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TodoListsTableCompanion.insert({
    required String id,
    required String title,
    this.color = const Value.absent(),
    this.notifyOnEnter = const Value.absent(),
    this.notifyOnExit = const Value.absent(),
    this.geofenceId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        createdAt = Value(createdAt);
  static Insertable<TodoListsTableData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? color,
    Expression<bool>? notifyOnEnter,
    Expression<bool>? notifyOnExit,
    Expression<String>? geofenceId,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (color != null) 'color': color,
      if (notifyOnEnter != null) 'notify_on_enter': notifyOnEnter,
      if (notifyOnExit != null) 'notify_on_exit': notifyOnExit,
      if (geofenceId != null) 'geofence_id': geofenceId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TodoListsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<int>? color,
      Value<bool>? notifyOnEnter,
      Value<bool>? notifyOnExit,
      Value<String?>? geofenceId,
      Value<int>? sortOrder,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return TodoListsTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      color: color ?? this.color,
      notifyOnEnter: notifyOnEnter ?? this.notifyOnEnter,
      notifyOnExit: notifyOnExit ?? this.notifyOnExit,
      geofenceId: geofenceId ?? this.geofenceId,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (notifyOnEnter.present) {
      map['notify_on_enter'] = Variable<bool>(notifyOnEnter.value);
    }
    if (notifyOnExit.present) {
      map['notify_on_exit'] = Variable<bool>(notifyOnExit.value);
    }
    if (geofenceId.present) {
      map['geofence_id'] = Variable<String>(geofenceId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodoListsTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('color: $color, ')
          ..write('notifyOnEnter: $notifyOnEnter, ')
          ..write('notifyOnExit: $notifyOnExit, ')
          ..write('geofenceId: $geofenceId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TodoItemsTableTable extends TodoItemsTable
    with TableInfo<$TodoItemsTableTable, TodoItemsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodoItemsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
      'list_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES todo_lists (id) ON DELETE CASCADE'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
      'is_done', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_done" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, listId, title, notes, isDone, dueDate, priority, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todo_items';
  @override
  VerificationContext validateIntegrity(Insertable<TodoItemsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('list_id')) {
      context.handle(_listIdMeta,
          listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta));
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('is_done')) {
      context.handle(_isDoneMeta,
          isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TodoItemsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TodoItemsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      listId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}list_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      isDone: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_done'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TodoItemsTableTable createAlias(String alias) {
    return $TodoItemsTableTable(attachedDatabase, alias);
  }
}

class TodoItemsTableData extends DataClass
    implements Insertable<TodoItemsTableData> {
  /// Primary key — UUID string.
  final String id;

  /// FK to the owning list — cascades on delete.
  final String listId;

  /// Display title of the item.
  final String title;

  /// Optional extended notes.
  final String? notes;

  /// Whether this item has been completed.
  final bool isDone;

  /// Optional due date.
  final DateTime? dueDate;

  /// Priority level: 0 = none, 1 = low, 2 = medium, 3 = high.
  final int priority;

  /// When this item was first created.
  final DateTime createdAt;
  const TodoItemsTableData(
      {required this.id,
      required this.listId,
      required this.title,
      this.notes,
      required this.isDone,
      this.dueDate,
      required this.priority,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['list_id'] = Variable<String>(listId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_done'] = Variable<bool>(isDone);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['priority'] = Variable<int>(priority);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TodoItemsTableCompanion toCompanion(bool nullToAbsent) {
    return TodoItemsTableCompanion(
      id: Value(id),
      listId: Value(listId),
      title: Value(title),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      isDone: Value(isDone),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      priority: Value(priority),
      createdAt: Value(createdAt),
    );
  }

  factory TodoItemsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoItemsTableData(
      id: serializer.fromJson<String>(json['id']),
      listId: serializer.fromJson<String>(json['listId']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String?>(json['notes']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      priority: serializer.fromJson<int>(json['priority']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'listId': serializer.toJson<String>(listId),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String?>(notes),
      'isDone': serializer.toJson<bool>(isDone),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'priority': serializer.toJson<int>(priority),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TodoItemsTableData copyWith(
          {String? id,
          String? listId,
          String? title,
          Value<String?> notes = const Value.absent(),
          bool? isDone,
          Value<DateTime?> dueDate = const Value.absent(),
          int? priority,
          DateTime? createdAt}) =>
      TodoItemsTableData(
        id: id ?? this.id,
        listId: listId ?? this.listId,
        title: title ?? this.title,
        notes: notes.present ? notes.value : this.notes,
        isDone: isDone ?? this.isDone,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        priority: priority ?? this.priority,
        createdAt: createdAt ?? this.createdAt,
      );
  TodoItemsTableData copyWithCompanion(TodoItemsTableCompanion data) {
    return TodoItemsTableData(
      id: data.id.present ? data.id.value : this.id,
      listId: data.listId.present ? data.listId.value : this.listId,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      priority: data.priority.present ? data.priority.value : this.priority,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TodoItemsTableData(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('isDone: $isDone, ')
          ..write('dueDate: $dueDate, ')
          ..write('priority: $priority, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, listId, title, notes, isDone, dueDate, priority, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoItemsTableData &&
          other.id == this.id &&
          other.listId == this.listId &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.isDone == this.isDone &&
          other.dueDate == this.dueDate &&
          other.priority == this.priority &&
          other.createdAt == this.createdAt);
}

class TodoItemsTableCompanion extends UpdateCompanion<TodoItemsTableData> {
  final Value<String> id;
  final Value<String> listId;
  final Value<String> title;
  final Value<String?> notes;
  final Value<bool> isDone;
  final Value<DateTime?> dueDate;
  final Value<int> priority;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TodoItemsTableCompanion({
    this.id = const Value.absent(),
    this.listId = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.isDone = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.priority = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TodoItemsTableCompanion.insert({
    required String id,
    required String listId,
    required String title,
    this.notes = const Value.absent(),
    this.isDone = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.priority = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        listId = Value(listId),
        title = Value(title),
        createdAt = Value(createdAt);
  static Insertable<TodoItemsTableData> custom({
    Expression<String>? id,
    Expression<String>? listId,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<bool>? isDone,
    Expression<DateTime>? dueDate,
    Expression<int>? priority,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listId != null) 'list_id': listId,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (isDone != null) 'is_done': isDone,
      if (dueDate != null) 'due_date': dueDate,
      if (priority != null) 'priority': priority,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TodoItemsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? listId,
      Value<String>? title,
      Value<String?>? notes,
      Value<bool>? isDone,
      Value<DateTime?>? dueDate,
      Value<int>? priority,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return TodoItemsTableCompanion(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      isDone: isDone ?? this.isDone,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodoItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('isDone: $isDone, ')
          ..write('dueDate: $dueDate, ')
          ..write('priority: $priority, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GeofenceRegionsTableTable extends GeofenceRegionsTable
    with TableInfo<$GeofenceRegionsTableTable, GeofenceRegionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GeofenceRegionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _radiusMetersMeta =
      const VerificationMeta('radiusMeters');
  @override
  late final GeneratedColumn<double> radiusMeters = GeneratedColumn<double>(
      'radius_meters', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _triggerMeta =
      const VerificationMeta('trigger');
  @override
  late final GeneratedColumn<String> trigger = GeneratedColumn<String>(
      'trigger', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('enter'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        latitude,
        longitude,
        radiusMeters,
        label,
        isActive,
        trigger,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'geofence_regions';
  @override
  VerificationContext validateIntegrity(
      Insertable<GeofenceRegionsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('radius_meters')) {
      context.handle(
          _radiusMetersMeta,
          radiusMeters.isAcceptableOrUnknown(
              data['radius_meters']!, _radiusMetersMeta));
    } else if (isInserting) {
      context.missing(_radiusMetersMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('trigger')) {
      context.handle(_triggerMeta,
          trigger.isAcceptableOrUnknown(data['trigger']!, _triggerMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GeofenceRegionsTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GeofenceRegionsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      radiusMeters: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}radius_meters'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      trigger: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}trigger'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $GeofenceRegionsTableTable createAlias(String alias) {
    return $GeofenceRegionsTableTable(attachedDatabase, alias);
  }
}

class GeofenceRegionsTableData extends DataClass
    implements Insertable<GeofenceRegionsTableData> {
  /// Primary key — UUID string.
  final String id;

  /// Latitude of the region centre, in degrees.
  final double latitude;

  /// Longitude of the region centre, in degrees.
  final double longitude;

  /// Radius of the region in metres.
  final double radiusMeters;

  /// Human-readable label for this region.
  final String label;

  /// Whether this region is currently registered with the OS.
  final bool isActive;

  /// Which transition(s) cause this region to fire ('enter', 'exit',
  /// 'enterAndExit').
  final String trigger;

  /// When this region was first created.
  final DateTime createdAt;
  const GeofenceRegionsTableData(
      {required this.id,
      required this.latitude,
      required this.longitude,
      required this.radiusMeters,
      required this.label,
      required this.isActive,
      required this.trigger,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['radius_meters'] = Variable<double>(radiusMeters);
    map['label'] = Variable<String>(label);
    map['is_active'] = Variable<bool>(isActive);
    map['trigger'] = Variable<String>(trigger);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GeofenceRegionsTableCompanion toCompanion(bool nullToAbsent) {
    return GeofenceRegionsTableCompanion(
      id: Value(id),
      latitude: Value(latitude),
      longitude: Value(longitude),
      radiusMeters: Value(radiusMeters),
      label: Value(label),
      isActive: Value(isActive),
      trigger: Value(trigger),
      createdAt: Value(createdAt),
    );
  }

  factory GeofenceRegionsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GeofenceRegionsTableData(
      id: serializer.fromJson<String>(json['id']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      radiusMeters: serializer.fromJson<double>(json['radiusMeters']),
      label: serializer.fromJson<String>(json['label']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      trigger: serializer.fromJson<String>(json['trigger']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'radiusMeters': serializer.toJson<double>(radiusMeters),
      'label': serializer.toJson<String>(label),
      'isActive': serializer.toJson<bool>(isActive),
      'trigger': serializer.toJson<String>(trigger),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GeofenceRegionsTableData copyWith(
          {String? id,
          double? latitude,
          double? longitude,
          double? radiusMeters,
          String? label,
          bool? isActive,
          String? trigger,
          DateTime? createdAt}) =>
      GeofenceRegionsTableData(
        id: id ?? this.id,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        radiusMeters: radiusMeters ?? this.radiusMeters,
        label: label ?? this.label,
        isActive: isActive ?? this.isActive,
        trigger: trigger ?? this.trigger,
        createdAt: createdAt ?? this.createdAt,
      );
  GeofenceRegionsTableData copyWithCompanion(
      GeofenceRegionsTableCompanion data) {
    return GeofenceRegionsTableData(
      id: data.id.present ? data.id.value : this.id,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      radiusMeters: data.radiusMeters.present
          ? data.radiusMeters.value
          : this.radiusMeters,
      label: data.label.present ? data.label.value : this.label,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      trigger: data.trigger.present ? data.trigger.value : this.trigger,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GeofenceRegionsTableData(')
          ..write('id: $id, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('radiusMeters: $radiusMeters, ')
          ..write('label: $label, ')
          ..write('isActive: $isActive, ')
          ..write('trigger: $trigger, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, latitude, longitude, radiusMeters, label,
      isActive, trigger, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GeofenceRegionsTableData &&
          other.id == this.id &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.radiusMeters == this.radiusMeters &&
          other.label == this.label &&
          other.isActive == this.isActive &&
          other.trigger == this.trigger &&
          other.createdAt == this.createdAt);
}

class GeofenceRegionsTableCompanion
    extends UpdateCompanion<GeofenceRegionsTableData> {
  final Value<String> id;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double> radiusMeters;
  final Value<String> label;
  final Value<bool> isActive;
  final Value<String> trigger;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const GeofenceRegionsTableCompanion({
    this.id = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.radiusMeters = const Value.absent(),
    this.label = const Value.absent(),
    this.isActive = const Value.absent(),
    this.trigger = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GeofenceRegionsTableCompanion.insert({
    required String id,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    this.label = const Value.absent(),
    this.isActive = const Value.absent(),
    this.trigger = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        latitude = Value(latitude),
        longitude = Value(longitude),
        radiusMeters = Value(radiusMeters),
        createdAt = Value(createdAt);
  static Insertable<GeofenceRegionsTableData> custom({
    Expression<String>? id,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? radiusMeters,
    Expression<String>? label,
    Expression<bool>? isActive,
    Expression<String>? trigger,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radiusMeters != null) 'radius_meters': radiusMeters,
      if (label != null) 'label': label,
      if (isActive != null) 'is_active': isActive,
      if (trigger != null) 'trigger': trigger,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GeofenceRegionsTableCompanion copyWith(
      {Value<String>? id,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<double>? radiusMeters,
      Value<String>? label,
      Value<bool>? isActive,
      Value<String>? trigger,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return GeofenceRegionsTableCompanion(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      label: label ?? this.label,
      isActive: isActive ?? this.isActive,
      trigger: trigger ?? this.trigger,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (radiusMeters.present) {
      map['radius_meters'] = Variable<double>(radiusMeters.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (trigger.present) {
      map['trigger'] = Variable<String>(trigger.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GeofenceRegionsTableCompanion(')
          ..write('id: $id, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('radiusMeters: $radiusMeters, ')
          ..write('label: $label, ')
          ..write('isActive: $isActive, ')
          ..write('trigger: $trigger, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TodoListsTableTable todoListsTable = $TodoListsTableTable(this);
  late final $TodoItemsTableTable todoItemsTable = $TodoItemsTableTable(this);
  late final $GeofenceRegionsTableTable geofenceRegionsTable =
      $GeofenceRegionsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [todoListsTable, todoItemsTable, geofenceRegionsTable];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('todo_lists',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('todo_items', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$TodoListsTableTableCreateCompanionBuilder = TodoListsTableCompanion
    Function({
  required String id,
  required String title,
  Value<int> color,
  Value<bool> notifyOnEnter,
  Value<bool> notifyOnExit,
  Value<String?> geofenceId,
  Value<int> sortOrder,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$TodoListsTableTableUpdateCompanionBuilder = TodoListsTableCompanion
    Function({
  Value<String> id,
  Value<String> title,
  Value<int> color,
  Value<bool> notifyOnEnter,
  Value<bool> notifyOnExit,
  Value<String?> geofenceId,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$TodoListsTableTableReferences extends BaseReferences<
    _$AppDatabase, $TodoListsTableTable, TodoListsTableData> {
  $$TodoListsTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TodoItemsTableTable, List<TodoItemsTableData>>
      _todoItemsTableRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.todoItemsTable,
              aliasName: $_aliasNameGenerator(
                  db.todoListsTable.id, db.todoItemsTable.listId));

  $$TodoItemsTableTableProcessedTableManager get todoItemsTableRefs {
    final manager = $$TodoItemsTableTableTableManager($_db, $_db.todoItemsTable)
        .filter((f) => f.listId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_todoItemsTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TodoListsTableTableFilterComposer
    extends Composer<_$AppDatabase, $TodoListsTableTable> {
  $$TodoListsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get notifyOnEnter => $composableBuilder(
      column: $table.notifyOnEnter, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get notifyOnExit => $composableBuilder(
      column: $table.notifyOnExit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get geofenceId => $composableBuilder(
      column: $table.geofenceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> todoItemsTableRefs(
      Expression<bool> Function($$TodoItemsTableTableFilterComposer f) f) {
    final $$TodoItemsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.todoItemsTable,
        getReferencedColumn: (t) => t.listId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TodoItemsTableTableFilterComposer(
              $db: $db,
              $table: $db.todoItemsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TodoListsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TodoListsTableTable> {
  $$TodoListsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get notifyOnEnter => $composableBuilder(
      column: $table.notifyOnEnter,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get notifyOnExit => $composableBuilder(
      column: $table.notifyOnExit,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get geofenceId => $composableBuilder(
      column: $table.geofenceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$TodoListsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TodoListsTableTable> {
  $$TodoListsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get notifyOnEnter => $composableBuilder(
      column: $table.notifyOnEnter, builder: (column) => column);

  GeneratedColumn<bool> get notifyOnExit => $composableBuilder(
      column: $table.notifyOnExit, builder: (column) => column);

  GeneratedColumn<String> get geofenceId => $composableBuilder(
      column: $table.geofenceId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> todoItemsTableRefs<T extends Object>(
      Expression<T> Function($$TodoItemsTableTableAnnotationComposer a) f) {
    final $$TodoItemsTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.todoItemsTable,
        getReferencedColumn: (t) => t.listId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TodoItemsTableTableAnnotationComposer(
              $db: $db,
              $table: $db.todoItemsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TodoListsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TodoListsTableTable,
    TodoListsTableData,
    $$TodoListsTableTableFilterComposer,
    $$TodoListsTableTableOrderingComposer,
    $$TodoListsTableTableAnnotationComposer,
    $$TodoListsTableTableCreateCompanionBuilder,
    $$TodoListsTableTableUpdateCompanionBuilder,
    (TodoListsTableData, $$TodoListsTableTableReferences),
    TodoListsTableData,
    PrefetchHooks Function({bool todoItemsTableRefs})> {
  $$TodoListsTableTableTableManager(
      _$AppDatabase db, $TodoListsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodoListsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodoListsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodoListsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<int> color = const Value.absent(),
            Value<bool> notifyOnEnter = const Value.absent(),
            Value<bool> notifyOnExit = const Value.absent(),
            Value<String?> geofenceId = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TodoListsTableCompanion(
            id: id,
            title: title,
            color: color,
            notifyOnEnter: notifyOnEnter,
            notifyOnExit: notifyOnExit,
            geofenceId: geofenceId,
            sortOrder: sortOrder,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<int> color = const Value.absent(),
            Value<bool> notifyOnEnter = const Value.absent(),
            Value<bool> notifyOnExit = const Value.absent(),
            Value<String?> geofenceId = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TodoListsTableCompanion.insert(
            id: id,
            title: title,
            color: color,
            notifyOnEnter: notifyOnEnter,
            notifyOnExit: notifyOnExit,
            geofenceId: geofenceId,
            sortOrder: sortOrder,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TodoListsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({todoItemsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (todoItemsTableRefs) db.todoItemsTable
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (todoItemsTableRefs)
                    await $_getPrefetchedData<TodoListsTableData,
                            $TodoListsTableTable, TodoItemsTableData>(
                        currentTable: table,
                        referencedTable: $$TodoListsTableTableReferences
                            ._todoItemsTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TodoListsTableTableReferences(db, table, p0)
                                .todoItemsTableRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.listId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TodoListsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TodoListsTableTable,
    TodoListsTableData,
    $$TodoListsTableTableFilterComposer,
    $$TodoListsTableTableOrderingComposer,
    $$TodoListsTableTableAnnotationComposer,
    $$TodoListsTableTableCreateCompanionBuilder,
    $$TodoListsTableTableUpdateCompanionBuilder,
    (TodoListsTableData, $$TodoListsTableTableReferences),
    TodoListsTableData,
    PrefetchHooks Function({bool todoItemsTableRefs})>;
typedef $$TodoItemsTableTableCreateCompanionBuilder = TodoItemsTableCompanion
    Function({
  required String id,
  required String listId,
  required String title,
  Value<String?> notes,
  Value<bool> isDone,
  Value<DateTime?> dueDate,
  Value<int> priority,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$TodoItemsTableTableUpdateCompanionBuilder = TodoItemsTableCompanion
    Function({
  Value<String> id,
  Value<String> listId,
  Value<String> title,
  Value<String?> notes,
  Value<bool> isDone,
  Value<DateTime?> dueDate,
  Value<int> priority,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$TodoItemsTableTableReferences extends BaseReferences<
    _$AppDatabase, $TodoItemsTableTable, TodoItemsTableData> {
  $$TodoItemsTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $TodoListsTableTable _listIdTable(_$AppDatabase db) =>
      db.todoListsTable.createAlias(
          $_aliasNameGenerator(db.todoItemsTable.listId, db.todoListsTable.id));

  $$TodoListsTableTableProcessedTableManager get listId {
    final $_column = $_itemColumn<String>('list_id')!;

    final manager = $$TodoListsTableTableTableManager($_db, $_db.todoListsTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TodoItemsTableTableFilterComposer
    extends Composer<_$AppDatabase, $TodoItemsTableTable> {
  $$TodoItemsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDone => $composableBuilder(
      column: $table.isDone, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$TodoListsTableTableFilterComposer get listId {
    final $$TodoListsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listId,
        referencedTable: $db.todoListsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TodoListsTableTableFilterComposer(
              $db: $db,
              $table: $db.todoListsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TodoItemsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TodoItemsTableTable> {
  $$TodoItemsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDone => $composableBuilder(
      column: $table.isDone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$TodoListsTableTableOrderingComposer get listId {
    final $$TodoListsTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listId,
        referencedTable: $db.todoListsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TodoListsTableTableOrderingComposer(
              $db: $db,
              $table: $db.todoListsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TodoItemsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TodoItemsTableTable> {
  $$TodoItemsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$TodoListsTableTableAnnotationComposer get listId {
    final $$TodoListsTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.listId,
        referencedTable: $db.todoListsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TodoListsTableTableAnnotationComposer(
              $db: $db,
              $table: $db.todoListsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TodoItemsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TodoItemsTableTable,
    TodoItemsTableData,
    $$TodoItemsTableTableFilterComposer,
    $$TodoItemsTableTableOrderingComposer,
    $$TodoItemsTableTableAnnotationComposer,
    $$TodoItemsTableTableCreateCompanionBuilder,
    $$TodoItemsTableTableUpdateCompanionBuilder,
    (TodoItemsTableData, $$TodoItemsTableTableReferences),
    TodoItemsTableData,
    PrefetchHooks Function({bool listId})> {
  $$TodoItemsTableTableTableManager(
      _$AppDatabase db, $TodoItemsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodoItemsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodoItemsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodoItemsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> listId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> isDone = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TodoItemsTableCompanion(
            id: id,
            listId: listId,
            title: title,
            notes: notes,
            isDone: isDone,
            dueDate: dueDate,
            priority: priority,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String listId,
            required String title,
            Value<String?> notes = const Value.absent(),
            Value<bool> isDone = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<int> priority = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TodoItemsTableCompanion.insert(
            id: id,
            listId: listId,
            title: title,
            notes: notes,
            isDone: isDone,
            dueDate: dueDate,
            priority: priority,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TodoItemsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({listId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (listId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.listId,
                    referencedTable:
                        $$TodoItemsTableTableReferences._listIdTable(db),
                    referencedColumn:
                        $$TodoItemsTableTableReferences._listIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TodoItemsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TodoItemsTableTable,
    TodoItemsTableData,
    $$TodoItemsTableTableFilterComposer,
    $$TodoItemsTableTableOrderingComposer,
    $$TodoItemsTableTableAnnotationComposer,
    $$TodoItemsTableTableCreateCompanionBuilder,
    $$TodoItemsTableTableUpdateCompanionBuilder,
    (TodoItemsTableData, $$TodoItemsTableTableReferences),
    TodoItemsTableData,
    PrefetchHooks Function({bool listId})>;
typedef $$GeofenceRegionsTableTableCreateCompanionBuilder
    = GeofenceRegionsTableCompanion Function({
  required String id,
  required double latitude,
  required double longitude,
  required double radiusMeters,
  Value<String> label,
  Value<bool> isActive,
  Value<String> trigger,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$GeofenceRegionsTableTableUpdateCompanionBuilder
    = GeofenceRegionsTableCompanion Function({
  Value<String> id,
  Value<double> latitude,
  Value<double> longitude,
  Value<double> radiusMeters,
  Value<String> label,
  Value<bool> isActive,
  Value<String> trigger,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$GeofenceRegionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $GeofenceRegionsTableTable> {
  $$GeofenceRegionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get radiusMeters => $composableBuilder(
      column: $table.radiusMeters, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trigger => $composableBuilder(
      column: $table.trigger, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$GeofenceRegionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GeofenceRegionsTableTable> {
  $$GeofenceRegionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get radiusMeters => $composableBuilder(
      column: $table.radiusMeters,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trigger => $composableBuilder(
      column: $table.trigger, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$GeofenceRegionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GeofenceRegionsTableTable> {
  $$GeofenceRegionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get radiusMeters => $composableBuilder(
      column: $table.radiusMeters, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get trigger =>
      $composableBuilder(column: $table.trigger, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$GeofenceRegionsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GeofenceRegionsTableTable,
    GeofenceRegionsTableData,
    $$GeofenceRegionsTableTableFilterComposer,
    $$GeofenceRegionsTableTableOrderingComposer,
    $$GeofenceRegionsTableTableAnnotationComposer,
    $$GeofenceRegionsTableTableCreateCompanionBuilder,
    $$GeofenceRegionsTableTableUpdateCompanionBuilder,
    (
      GeofenceRegionsTableData,
      BaseReferences<_$AppDatabase, $GeofenceRegionsTableTable,
          GeofenceRegionsTableData>
    ),
    GeofenceRegionsTableData,
    PrefetchHooks Function()> {
  $$GeofenceRegionsTableTableTableManager(
      _$AppDatabase db, $GeofenceRegionsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GeofenceRegionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GeofenceRegionsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GeofenceRegionsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<double> latitude = const Value.absent(),
            Value<double> longitude = const Value.absent(),
            Value<double> radiusMeters = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String> trigger = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GeofenceRegionsTableCompanion(
            id: id,
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters,
            label: label,
            isActive: isActive,
            trigger: trigger,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required double latitude,
            required double longitude,
            required double radiusMeters,
            Value<String> label = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String> trigger = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              GeofenceRegionsTableCompanion.insert(
            id: id,
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters,
            label: label,
            isActive: isActive,
            trigger: trigger,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GeofenceRegionsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $GeofenceRegionsTableTable,
        GeofenceRegionsTableData,
        $$GeofenceRegionsTableTableFilterComposer,
        $$GeofenceRegionsTableTableOrderingComposer,
        $$GeofenceRegionsTableTableAnnotationComposer,
        $$GeofenceRegionsTableTableCreateCompanionBuilder,
        $$GeofenceRegionsTableTableUpdateCompanionBuilder,
        (
          GeofenceRegionsTableData,
          BaseReferences<_$AppDatabase, $GeofenceRegionsTableTable,
              GeofenceRegionsTableData>
        ),
        GeofenceRegionsTableData,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TodoListsTableTableTableManager get todoListsTable =>
      $$TodoListsTableTableTableManager(_db, _db.todoListsTable);
  $$TodoItemsTableTableTableManager get todoItemsTable =>
      $$TodoItemsTableTableTableManager(_db, _db.todoItemsTable);
  $$GeofenceRegionsTableTableTableManager get geofenceRegionsTable =>
      $$GeofenceRegionsTableTableTableManager(_db, _db.geofenceRegionsTable);
}
