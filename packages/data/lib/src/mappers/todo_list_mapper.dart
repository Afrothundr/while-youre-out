import 'package:data/src/database/app_database.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

/// Converts a drift [TodoListsTableData] row to a domain [TodoList].
extension TodoListRowMapper on TodoListsTableData {
  /// Maps this drift row to its domain representation.
  TodoList toDomain() => TodoList(
        id: id,
        title: title,
        color: color,
        notifyOnEnter: notifyOnEnter,
        notifyOnExit: notifyOnExit,
        geofenceId: geofenceId,
        sortOrder: sortOrder,
        createdAt: createdAt,
      );
}

/// Converts a domain [TodoList] to a drift [TodoListsTableCompanion].
extension TodoListDomainMapper on TodoList {
  /// Maps this domain entity to a drift companion suitable for insert/update.
  TodoListsTableCompanion toCompanion() => TodoListsTableCompanion(
        id: Value(id),
        title: Value(title),
        color: Value(color),
        notifyOnEnter: Value(notifyOnEnter),
        notifyOnExit: Value(notifyOnExit),
        geofenceId: Value(geofenceId),
        sortOrder: Value(sortOrder),
        createdAt: Value(createdAt),
      );
}
