import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whileyoureout/providers/providers.dart';
import 'package:whileyoureout/screens/dashboard/dashboard_screen.dart';
import 'package:whileyoureout/screens/dashboard/dashboard_view_model.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockTodoListRepository extends Mock implements TodoListRepository {}

class MockTodoItemRepository extends Mock implements TodoItemRepository {}

class MockGeofenceRepository extends Mock implements GeofenceRepository {}

class MockGeofenceService extends Mock implements GeofenceService {}

class MockCreateListUseCase extends Mock implements CreateListUseCase {}

class MockDeleteListUseCase extends Mock implements DeleteListUseCase {}

class MockReorderListsUseCase extends Mock implements ReorderListsUseCase {}

// ---------------------------------------------------------------------------
// Helpers — ProviderContainer for ViewModel-level tests
// ---------------------------------------------------------------------------

/// Builds a [ProviderContainer] wired up with a fake lists stream and the
/// provided [reorderUseCase], then returns both the container and the notifier.
///
/// Callers are responsible for calling `container.dispose()` via
/// [addTearDown].
ProviderContainer _buildViewModelContainer({
  required List<TodoList> lists,
  required MockReorderListsUseCase reorderUseCase,
}) {
  return ProviderContainer(
    overrides: [
      allListsStreamProvider.overrideWith((ref) => Stream.value(lists)),
      reorderListsUseCaseProvider.overrideWithValue(reorderUseCase),
    ],
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns a minimal [TodoList] for testing.
TodoList _makeList({
  String id = 'list-1',
  String title = 'Groceries',
  int color = 0xFF2196F3,
  String? geofenceId,
  int sortOrder = 0,
}) {
  return TodoList(
    id: id,
    title: title,
    color: color,
    geofenceId: geofenceId,
    sortOrder: sortOrder,
    createdAt: DateTime(2024),
  );
}

/// Builds a [ProviderScope] with overrides that inject the given stream and
/// mocked repositories/use-cases, then pumps [DashboardScreen].
Widget _buildHarness({
  required Stream<List<TodoList>> listsStream,
  MockTodoItemRepository? itemRepo,
  MockCreateListUseCase? createListUseCase,
  MockDeleteListUseCase? deleteListUseCase,
}) {
  final mockListRepo = MockTodoListRepository();
  final mockItemRepo = itemRepo ?? MockTodoItemRepository();
  final mockGeoRepo = MockGeofenceRepository();
  final mockGeoService = MockGeofenceService();
  final mockCreate = createListUseCase ?? MockCreateListUseCase();
  final mockDelete = deleteListUseCase ?? MockDeleteListUseCase();
  final mockReorder = MockReorderListsUseCase();

  // Default stub: no incomplete items for any list.
  when(() => mockItemRepo.countIncompleteItems(any()))
      .thenAnswer((_) async => 0);
  when(() => mockItemRepo.watchItemsForList(any()))
      .thenAnswer((_) => const Stream.empty());

  return ProviderScope(
    overrides: [
      // Provide a fake stream directly into the StreamProvider so we never
      // touch the real AppDatabase or path_provider.
      allListsStreamProvider.overrideWith(
        (ref) => listsStream,
      ),
      todoListRepositoryProvider.overrideWithValue(mockListRepo),
      todoItemRepositoryProvider.overrideWithValue(mockItemRepo),
      geofenceRepositoryProvider.overrideWithValue(mockGeoRepo),
      geofenceServiceProvider.overrideWithValue(mockGeoService),
      createListUseCaseProvider.overrideWithValue(mockCreate),
      deleteListUseCaseProvider.overrideWithValue(mockDelete),
      reorderListsUseCaseProvider.overrideWithValue(mockReorder),
    ],
    child: const MaterialApp(
      home: DashboardScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DashboardScreen', () {
    testWidgets('shows empty state when there are no lists', (tester) async {
      await tester.pumpWidget(
        _buildHarness(listsStream: Stream.value([])),
      );
      await tester.pump(); // let the stream emit

      expect(find.text('No lists yet'), findsOneWidget);
      expect(find.text('Tap + to create one.'), findsOneWidget);
      expect(find.byIcon(Icons.checklist), findsOneWidget);
    });

    testWidgets('shows a tile for each list when lists exist', (tester) async {
      final lists = [
        _makeList(id: 'a'),
        _makeList(id: 'b', title: 'Hardware store', sortOrder: 1),
      ];

      await tester.pumpWidget(
        _buildHarness(listsStream: Stream.value(lists)),
      );
      await tester.pump();

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Hardware store'), findsOneWidget);
      expect(find.text('No lists yet'), findsNothing);
    });

    testWidgets('FAB is present on the dashboard', (tester) async {
      await tester.pumpWidget(
        _buildHarness(listsStream: Stream.value([])),
      );
      await tester.pump();

      expect(find.byKey(const Key('dashboard_fab')), findsOneWidget);
    });

    testWidgets('tapping FAB opens CreateListBottomSheet', (tester) async {
      await tester.pumpWidget(
        _buildHarness(listsStream: Stream.value([])),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('dashboard_fab')));
      await tester.pumpAndSettle();

      // The bottom sheet contains the "New List" heading and a title field.
      expect(find.text('New List'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('long-pressing a tile shows delete confirmation dialog',
        (tester) async {
      final lists = [_makeList()];

      await tester.pumpWidget(
        _buildHarness(listsStream: Stream.value(lists)),
      );
      await tester.pump();

      await tester.longPress(find.text('Groceries'));
      await tester.pumpAndSettle();

      expect(find.text('Delete list?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('cancelling delete dialog does not call deleteList',
        (tester) async {
      final mockDelete = MockDeleteListUseCase();
      final lists = [_makeList()];

      await tester.pumpWidget(
        _buildHarness(
          listsStream: Stream.value(lists),
          deleteListUseCase: mockDelete,
        ),
      );
      await tester.pump();

      await tester.longPress(find.text('Groceries'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockDelete.call(any()));
    });

    testWidgets('shows location pin icon for lists with a geofence',
        (tester) async {
      final lists = [
        _makeList(id: 'a', title: 'Store', geofenceId: 'geo-1'),
        _makeList(id: 'b', title: 'Home', sortOrder: 1),
      ];

      await tester.pumpWidget(
        _buildHarness(listsStream: Stream.value(lists)),
      );
      await tester.pump();

      // location_on icon should appear exactly once (for the geofenced list).
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('shows loading indicator while stream is loading',
        (tester) async {
      // A stream that never emits keeps the notifier in loading state.
      final neverStream = StreamController<List<TodoList>>();
      addTearDown(neverStream.close);

      await tester.pumpWidget(
        _buildHarness(listsStream: neverStream.stream),
      );
      // One pump — stream has not emitted yet so the provider is still loading.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows a drag handle for each list tile', (tester) async {
      final lists = [
        _makeList(id: 'a'),
        _makeList(id: 'b', title: 'Hardware store', sortOrder: 1),
        _makeList(id: 'c', title: 'Pharmacy', sortOrder: 2),
      ];

      await tester.pumpWidget(
        _buildHarness(listsStream: Stream.value(lists)),
      );
      await tester.pump();

      // One drag handle per list tile.
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(lists.length));
    });
  });

  // ---------------------------------------------------------------------------
  // DashboardViewModel unit tests
  // ---------------------------------------------------------------------------

  group('DashboardViewModel.reorderLists', () {
    test('calls ReorderListsUseCase with the correct ordered ID list',
        () async {
      final mockReorder = MockReorderListsUseCase();
      when(() => mockReorder.call(any())).thenAnswer((_) async {});

      final lists = [
        _makeList(id: 'list-a'),
        _makeList(id: 'list-b', sortOrder: 1),
      ];

      final container = _buildViewModelContainer(
        lists: lists,
        reorderUseCase: mockReorder,
      );
      addTearDown(container.dispose);

      // Subscribe so the autoDispose notifier is kept alive for the test.
      final subscription = container.listen(
        dashboardViewModelProvider,
        (_, __) {},
      );
      addTearDown(subscription.close);

      // Allow the stream to emit so the notifier is fully initialised.
      await Future<void>.delayed(Duration.zero);

      final viewModel =
          container.read(dashboardViewModelProvider.notifier);

      await viewModel.reorderLists(['list-b', 'list-a']);

      verify(() => mockReorder.call(['list-b', 'list-a'])).called(1);
    });

    test('does not change state on ReorderListsUseCase failure', () async {
      final mockReorder = MockReorderListsUseCase();
      when(() => mockReorder.call(any()))
          .thenThrow(Exception('reorder failed'));

      final lists = [
        _makeList(id: 'list-a'),
        _makeList(id: 'list-b', sortOrder: 1),
      ];

      final container = _buildViewModelContainer(
        lists: lists,
        reorderUseCase: mockReorder,
      );
      addTearDown(container.dispose);

      // Subscribe so the autoDispose notifier is kept alive for the test.
      final subscription = container.listen(
        dashboardViewModelProvider,
        (_, __) {},
      );
      addTearDown(subscription.close);

      await Future<void>.delayed(Duration.zero);

      final viewModel =
          container.read(dashboardViewModelProvider.notifier);

      // The call should not throw — errors are absorbed into state.
      await expectLater(
        () => viewModel.reorderLists(['list-b', 'list-a']),
        returnsNormally,
      );

      final state = container.read(dashboardViewModelProvider);
      expect(state.errorMessage, contains('reorder failed'));
    });
  });
}
