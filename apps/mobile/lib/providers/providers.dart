import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

/// The single [AppDatabase] instance for the app lifetime.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ---------------------------------------------------------------------------
// Repositories
// ---------------------------------------------------------------------------

/// Provides the [TodoListRepository] backed by the local Drift database.
final todoListRepositoryProvider = Provider<TodoListRepository>((ref) {
  return DriftTodoListRepository(ref.watch(appDatabaseProvider));
});

/// Provides the [TodoItemRepository] backed by the local Drift database.
final todoItemRepositoryProvider = Provider<TodoItemRepository>((ref) {
  return DriftTodoItemRepository(ref.watch(appDatabaseProvider));
});

/// Provides the [GeofenceRepository] backed by the local Drift database.
final geofenceRepositoryProvider = Provider<GeofenceRepository>((ref) {
  return DriftGeofenceRepository(ref.watch(appDatabaseProvider));
});

// ---------------------------------------------------------------------------
// No-op GeofenceService for Phase 1 (no background events)
// ---------------------------------------------------------------------------

/// Provides the [GeofenceService] (no-op stub for Phase 1).
final geofenceServiceProvider = Provider<GeofenceService>((ref) {
  return _NoOpGeofenceService();
});

// ---------------------------------------------------------------------------
// Use Cases
// ---------------------------------------------------------------------------

/// Provides the [CreateListUseCase].
final createListUseCaseProvider = Provider<CreateListUseCase>((ref) {
  return CreateListUseCase(ref.watch(todoListRepositoryProvider));
});

/// Provides the [DeleteListUseCase].
final deleteListUseCaseProvider = Provider<DeleteListUseCase>((ref) {
  return DeleteListUseCase(
    ref.watch(todoListRepositoryProvider),
    ref.watch(todoItemRepositoryProvider),
    ref.watch(geofenceRepositoryProvider),
    ref.watch(geofenceServiceProvider),
  );
});

/// Provides the [ReorderListsUseCase].
final reorderListsUseCaseProvider = Provider<ReorderListsUseCase>((ref) {
  return ReorderListsUseCase(ref.watch(todoListRepositoryProvider));
});

/// Provides the [CreateItemUseCase].
final createItemUseCaseProvider = Provider<CreateItemUseCase>((ref) {
  return CreateItemUseCase(ref.watch(todoItemRepositoryProvider));
});

/// Provides the [ToggleItemUseCase].
final toggleItemUseCaseProvider = Provider<ToggleItemUseCase>((ref) {
  return ToggleItemUseCase(ref.watch(todoItemRepositoryProvider));
});

/// Provides the [DeleteItemUseCase].
final deleteItemUseCaseProvider = Provider<DeleteItemUseCase>((ref) {
  return DeleteItemUseCase(ref.watch(todoItemRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Reactive streams
// ---------------------------------------------------------------------------

/// Stream of all [TodoList]s, ordered by sort order.
final allListsStreamProvider = StreamProvider<List<TodoList>>((ref) {
  return ref.watch(todoListRepositoryProvider).watchAllLists();
});

/// Stream of [TodoItem]s for a specific list ID.
final itemsStreamProvider =
    StreamProvider.family<List<TodoItem>, String>((ref, listId) {
  return ref.watch(todoItemRepositoryProvider).watchItemsForList(listId);
});

/// Incomplete item count for a specific list ID (future-based for badges).
final incompleteCountProvider =
    FutureProvider.family<int, String>((ref, listId) {
  return ref.watch(todoItemRepositoryProvider).countIncompleteItems(listId);
});

/// Single [TodoList] by ID, derived from the repository stream directly.
final listByIdProvider =
    StreamProvider.family<TodoList?, String>((ref, listId) {
  return ref.watch(todoListRepositoryProvider).watchAllLists().map(
        (lists) => lists.where((l) => l.id == listId).firstOrNull,
      );
});

// ---------------------------------------------------------------------------
// Private: no-op GeofenceService stub (Phase 1)
// ---------------------------------------------------------------------------

class _NoOpGeofenceService implements GeofenceService {
  @override
  Future<void> registerRegion(GeofenceRegion region) async {}

  @override
  Future<void> unregisterRegion(String regionId) async {}

  @override
  Future<void> unregisterAll() async {}

  @override
  Stream<GeofenceEvent> get events => const Stream.empty();
}
