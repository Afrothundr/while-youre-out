import 'package:equatable/equatable.dart';

/// A named collection of todo items, optionally tied to a geofence region.
class TodoList extends Equatable {
  /// Creates a [TodoList].
  const TodoList({
    required this.id,
    required this.title,
    required this.sortOrder,
    required this.createdAt,
    this.color = 0xFF2196F3,
    this.notifyOnEnter = true,
    this.notifyOnExit = false,
    this.geofenceId,
  });

  /// Unique identifier (UUID v4).
  final String id;

  /// Display title of the list.
  final String title;

  /// ARGB integer colour value used to visually distinguish this list.
  final int color;

  /// Whether to fire a notification when the device enters the geofence.
  final bool notifyOnEnter;

  /// Whether to fire a notification when the device exits the geofence.
  final bool notifyOnExit;

  /// Optional foreign key to a geofence region.
  final String? geofenceId;

  /// Zero-based sort position among all lists.
  final int sortOrder;

  /// When this list was first created.
  final DateTime createdAt;

  /// Returns a copy of this [TodoList] with the given fields replaced.
  TodoList copyWith({
    String? id,
    String? title,
    int? color,
    bool? notifyOnEnter,
    bool? notifyOnExit,
    Object? geofenceId = _sentinel,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return TodoList(
      id: id ?? this.id,
      title: title ?? this.title,
      color: color ?? this.color,
      notifyOnEnter: notifyOnEnter ?? this.notifyOnEnter,
      notifyOnExit: notifyOnExit ?? this.notifyOnExit,
      geofenceId:
          geofenceId == _sentinel ? this.geofenceId : geofenceId as String?,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        color,
        notifyOnEnter,
        notifyOnExit,
        geofenceId,
        sortOrder,
        createdAt,
      ];
}

/// Sentinel object used to distinguish "not provided" from explicit `null`
/// in [TodoList.copyWith].
const Object _sentinel = Object();
