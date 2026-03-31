import 'package:data/src/database/app_database.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

/// Converts a drift [TodoItemsTableData] row to a domain [TodoItem].
extension TodoItemRowMapper on TodoItemsTableData {
  /// Maps this drift row to its domain representation.
  TodoItem toDomain() => TodoItem(
        id: id,
        listId: listId,
        title: title,
        notes: notes,
        isDone: isDone,
        dueDate: dueDate,
        priority: priority,
        createdAt: createdAt,
      );
}

/// Converts a domain [TodoItem] to a drift [TodoItemsTableCompanion].
extension TodoItemDomainMapper on TodoItem {
  /// Maps this domain entity to a drift companion suitable for insert/update.
  TodoItemsTableCompanion toCompanion() => TodoItemsTableCompanion(
        id: Value(id),
        listId: Value(listId),
        title: Value(title),
        notes: Value(notes),
        isDone: Value(isDone),
        dueDate: Value(dueDate),
        priority: Value(priority),
        createdAt: Value(createdAt),
      );
}
