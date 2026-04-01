import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geofencing/geofencing.dart';
import 'package:notifications/notifications.dart';
import 'package:whileyoureout/geofence_event_handler.dart';
import 'package:whileyoureout/geofence_manager.dart';

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
// GeofenceService — Phase 3: RealGeofenceService (platform channel bridge)
// ---------------------------------------------------------------------------

/// Provides the [GeofenceService] implementation.
///
/// Uses [RealGeofenceService] which bridges to the native iOS
/// CLLocationManager and Android GeofencingClient via platform channels.
final geofenceServiceProvider = Provider<GeofenceService>((ref) {
  return RealGeofenceService();
});

// ---------------------------------------------------------------------------
// NotificationService
// ---------------------------------------------------------------------------

/// Provides the [NotificationService] implementation.
///
/// Uses [FlutterNotificationService] which is backed by
/// `flutter_local_notifications`. Call [FlutterNotificationService.initialize]
/// at app startup and register a tap callback once the router is ready.
final notificationServiceProvider = Provider<FlutterNotificationService>((ref) {
  return FlutterNotificationService();
});

// ---------------------------------------------------------------------------
// GeofenceManager
// ---------------------------------------------------------------------------

/// Provides the [RefreshActiveGeofencesUseCase].
final refreshActiveGeofencesUseCaseProvider =
    Provider<RefreshActiveGeofencesUseCase>((ref) {
  return RefreshActiveGeofencesUseCase(
    ref.watch(geofenceRepositoryProvider),
    ref.watch(geofenceServiceProvider),
  );
});

/// Provides the singleton [GeofenceManager].
///
/// Automatically disposes the manager (cancels position stream) when the
/// provider is no longer needed.
final geofenceManagerProvider = Provider<GeofenceManager>((ref) {
  final manager = GeofenceManager(
    geofenceService: ref.watch(geofenceServiceProvider),
    refreshActiveGeofences: ref.watch(refreshActiveGeofencesUseCaseProvider),
  );
  ref.onDispose(manager.dispose);
  return manager;
});

// ---------------------------------------------------------------------------
// GeofenceEventHandler
// ---------------------------------------------------------------------------

/// Provides the singleton [GeofenceEventHandler].
///
/// Automatically disposes the handler (cancels the geofence event stream
/// subscription) when the provider is no longer needed.
final geofenceEventHandlerProvider = Provider<GeofenceEventHandler>((ref) {
  final handler = GeofenceEventHandler(
    geofenceService: ref.watch(geofenceServiceProvider),
    handleEntry: ref.watch(handleGeofenceEntryUseCaseProvider),
  );
  ref.onDispose(handler.dispose);
  return handler;
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

/// Provides the [HandleGeofenceEntryUseCase].
final handleGeofenceEntryUseCaseProvider =
    Provider<HandleGeofenceEntryUseCase>((ref) {
  return HandleGeofenceEntryUseCase(
    ref.watch(todoListRepositoryProvider),
    ref.watch(todoItemRepositoryProvider),
    ref.watch(notificationServiceProvider),
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

/// Provides the [AssignLocationUseCase].
final assignLocationUseCaseProvider = Provider<AssignLocationUseCase>((ref) {
  return AssignLocationUseCase(
    ref.watch(todoListRepositoryProvider),
    ref.watch(geofenceRepositoryProvider),
  );
});

/// Provides the [RegisterGeofenceUseCase].
final registerGeofenceUseCaseProvider =
    Provider<RegisterGeofenceUseCase>((ref) {
  return RegisterGeofenceUseCase(
    ref.watch(geofenceRepositoryProvider),
    ref.watch(geofenceServiceProvider),
  );
});

/// Provides the [UnregisterGeofenceUseCase].
final unregisterGeofenceUseCaseProvider =
    Provider<UnregisterGeofenceUseCase>((ref) {
  return UnregisterGeofenceUseCase(
    ref.watch(geofenceRepositoryProvider),
    ref.watch(geofenceServiceProvider),
  );
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
