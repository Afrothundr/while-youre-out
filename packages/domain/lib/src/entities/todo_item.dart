import 'package:equatable/equatable.dart';

/// A single task belonging to a todo list.
class TodoItem extends Equatable {
  /// Creates a [TodoItem].
  const TodoItem({
    required this.id,
    required this.listId,
    required this.title,
    required this.createdAt,
    this.notes,
    this.isDone = false,
    this.dueDate,
    this.priority = 0,
  });

  /// Unique identifier (UUID v4).
  final String id;

  /// The ID of the todo list this item belongs to.
  final String listId;

  /// Display title of the item.
  final String title;

  /// When this item was first created.
  final DateTime createdAt;

  /// Optional extended notes for this item.
  final String? notes;

  /// Whether this item has been completed.
  final bool isDone;

  /// Optional due date for this item.
  final DateTime? dueDate;

  /// Priority level: 0 = none, 1 = low, 2 = medium, 3 = high.
  final int priority;

  /// Returns a copy of this [TodoItem] with the given fields replaced.
  TodoItem copyWith({
    String? id,
    String? listId,
    String? title,
    DateTime? createdAt,
    Object? notes = _sentinel,
    bool? isDone,
    Object? dueDate = _sentinel,
    int? priority,
  }) {
    return TodoItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      notes: notes == _sentinel ? this.notes : notes as String?,
      isDone: isDone ?? this.isDone,
      dueDate: dueDate == _sentinel ? this.dueDate : dueDate as DateTime?,
      priority: priority ?? this.priority,
    );
  }

  @override
  List<Object?> get props => [
        id,
        listId,
        title,
        createdAt,
        notes,
        isDone,
        dueDate,
        priority,
      ];
}

/// Sentinel object used to distinguish "not provided" from explicit `null`
/// in [TodoItem.copyWith].
const Object _sentinel = Object();
