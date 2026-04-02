import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:whileyoureout/providers/providers.dart';
import 'package:whileyoureout/screens/list_detail/list_detail_screen.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockTodoListRepository extends Mock implements TodoListRepository {}

class MockTodoItemRepository extends Mock implements TodoItemRepository {}

class MockGeofenceRepository extends Mock implements GeofenceRepository {}

class MockGeofenceService extends Mock implements GeofenceService {}

class MockToggleItemUseCase extends Mock implements ToggleItemUseCase {}

class MockCreateItemUseCase extends Mock implements CreateItemUseCase {}

class MockDeleteItemUseCase extends Mock implements DeleteItemUseCase {}

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

/// Returns a minimal [TodoItem] for testing.
TodoItem _makeItem({
  String id = 'item-1',
  String listId = 'list-1',
  String title = 'Buy milk',
  bool isDone = false,
}) {
  return TodoItem(
    id: id,
    listId: listId,
    title: title,
    isDone: isDone,
    createdAt: DateTime(2024),
  );
}

/// Wraps [ListDetailScreen] in a [ProviderScope] with the given stream
/// overrides.
Widget _buildHarness({
  required String listId,
  required Stream<List<TodoList>> listsStream,
  required Stream<List<TodoItem>> itemsStream,
  MockTodoItemRepository? itemRepo,
  MockToggleItemUseCase? toggleUseCase,
  MockCreateItemUseCase? createItemUseCase,
  MockDeleteItemUseCase? deleteItemUseCase,
}) {
  final mockListRepo = MockTodoListRepository();
  final mockItemRepo = itemRepo ?? MockTodoItemRepository();
  final mockGeoRepo = MockGeofenceRepository();
  final mockGeoService = MockGeofenceService();
  final mockToggle = toggleUseCase ?? MockToggleItemUseCase();
  final mockCreate = createItemUseCase ?? MockCreateItemUseCase();
  final mockDelete = deleteItemUseCase ?? MockDeleteItemUseCase();

  // Stub watchAllLists so listByIdProvider can derive the single list.
  // ignore: unnecessary_lambdas
  when(() => mockListRepo.watchAllLists()).thenAnswer((_) => listsStream);

  return ProviderScope(
    overrides: [
      // Stream overrides — no real DB needed.
      allListsStreamProvider.overrideWith((_) => listsStream),
      itemsStreamProvider.overrideWith((ref, id) => itemsStream),

      // Repository overrides.
      todoListRepositoryProvider.overrideWithValue(mockListRepo),
      todoItemRepositoryProvider.overrideWithValue(mockItemRepo),
      geofenceRepositoryProvider.overrideWithValue(mockGeoRepo),
      geofenceServiceProvider.overrideWithValue(mockGeoService),

      // Use-case overrides.
      toggleItemUseCaseProvider.overrideWithValue(mockToggle),
      createItemUseCaseProvider.overrideWithValue(mockCreate),
      deleteItemUseCaseProvider.overrideWithValue(mockDelete),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/list/$listId',
        routes: [
          GoRoute(
            path: '/list/:listId',
            builder: (context, state) =>
                ListDetailScreen(listId: state.pathParameters['listId']!),
            routes: [
                GoRoute(
                  path: 'location',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Location Detail')),
                ),
                GoRoute(
                  path: 'map',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Map Picker')),
                ),
              ],
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ListDetailScreen', () {
    testWidgets('shows loading indicator while streams are loading',
        (tester) async {
      final neverLists = StreamController<List<TodoList>>();
      final neverItems = StreamController<List<TodoItem>>();
      addTearDown(neverLists.close);
      addTearDown(neverItems.close);

      await tester.pumpWidget(
        _buildHarness(
          listId: 'list-1',
          listsStream: neverLists.stream,
          itemsStream: neverItems.stream,
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows list title in AppBar when list is loaded',
        (tester) async {
      final list = _makeList();

      await tester.pumpWidget(
        _buildHarness(
          listId: 'list-1',
          listsStream: Stream.value([list]),
          itemsStream: Stream.value([]),
        ),
      );
      await tester.pump();

      expect(find.text('Groceries'), findsOneWidget);
    });

    testWidgets('shows empty state when list has no items', (tester) async {
      final list = _makeList();

      await tester.pumpWidget(
        _buildHarness(
          listId: 'list-1',
          listsStream: Stream.value([list]),
          itemsStream: Stream.value([]),
        ),
      );
      await tester.pump();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(find.text('Add your first item below.'), findsOneWidget);
    });

    testWidgets('shows item checkboxes when list has items', (tester) async {
      final list = _makeList();
      final items = [
        _makeItem(id: 'i1'),
        _makeItem(id: 'i2', title: 'Buy eggs'),
      ];

      await tester.pumpWidget(
        _buildHarness(
          listId: 'list-1',
          listsStream: Stream.value([list]),
          itemsStream: Stream.value(items),
        ),
      );
      await tester.pump();

      expect(find.text('Buy milk'), findsOneWidget);
      expect(find.text('Buy eggs'), findsOneWidget);
      expect(find.byType(AppCheckbox), findsNWidgets(2));
      expect(find.byType(AppEmptyState), findsNothing);
    });

    testWidgets('tapping a checkbox calls toggleItem use case', (tester) async {
      final list = _makeList();
      final item = _makeItem();

      final mockToggle = MockToggleItemUseCase();
      when(() => mockToggle.call(any()))
          .thenAnswer((_) async => item.copyWith(isDone: true));

      await tester.pumpWidget(
        _buildHarness(
          listId: 'list-1',
          listsStream: Stream.value([list]),
          itemsStream: Stream.value([item]),
          toggleUseCase: mockToggle,
        ),
      );
      await tester.pump();

      // Tap the Checkbox widget itself.
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      verify(() => mockToggle.call('item-1')).called(1);
    });

    testWidgets('inline add-item field is visible', (tester) async {
      final list = _makeList();

      await tester.pumpWidget(
        _buildHarness(
          listId: 'list-1',
          listsStream: Stream.value([list]),
          itemsStream: Stream.value([]),
        ),
      );
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.add), findsOneWidget);
    });

    testWidgets('entering text and tapping add button calls createItem',
        (tester) async {
      final list = _makeList();
      final createdItem = _makeItem(id: 'new-1', title: 'Buy bread');

      final mockCreate = MockCreateItemUseCase();
      when(
        () => mockCreate.call(
          listId: any(named: 'listId'),
          title: any(named: 'title'),
        ),
      ).thenAnswer((_) async => createdItem);

      await tester.pumpWidget(
        _buildHarness(
          listId: 'list-1',
          listsStream: Stream.value([list]),
          itemsStream: Stream.value([]),
          createItemUseCase: mockCreate,
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Buy bread');
      await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
      await tester.pump();

      verify(
        () => mockCreate.call(listId: 'list-1', title: 'Buy bread'),
      ).called(1);
    });

    testWidgets('submitting via keyboard Done action calls createItem',
        (tester) async {
      final list = _makeList();
      final createdItem = _makeItem(id: 'new-1', title: 'Buy bread');

      final mockCreate = MockCreateItemUseCase();
      when(
        () => mockCreate.call(
          listId: any(named: 'listId'),
          title: any(named: 'title'),
        ),
      ).thenAnswer((_) async => createdItem);

      await tester.pumpWidget(
        _buildHarness(
          listId: 'list-1',
          listsStream: Stream.value([list]),
          itemsStream: Stream.value([]),
          createItemUseCase: mockCreate,
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Buy bread');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      verify(
        () => mockCreate.call(listId: 'list-1', title: 'Buy bread'),
      ).called(1);
    });

    testWidgets('does not call createItem when text field is empty',
        (tester) async {
      final list = _makeList();

      final mockCreate = MockCreateItemUseCase();

      await tester.pumpWidget(
        _buildHarness(
          listId: 'list-1',
          listsStream: Stream.value([list]),
          itemsStream: Stream.value([]),
          createItemUseCase: mockCreate,
        ),
      );
      await tester.pump();

      // Tap add without entering text.
      await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
      await tester.pump();

      verifyNever(
        () => mockCreate.call(
          listId: any(named: 'listId'),
          title: any(named: 'title'),
        ),
      );
    });

    testWidgets('shows location chip when list has a geofenceId',
        (tester) async {
      final list = _makeList(geofenceId: 'geo-42');

      await tester.pumpWidget(
        _buildHarness(
          listId: 'list-1',
          listsStream: Stream.value([list]),
          itemsStream: Stream.value([]),
        ),
      );
      await tester.pump();

      expect(find.byType(ActionChip), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('tapping location chip navigates to map picker',
        (tester) async {
      final list = _makeList(geofenceId: 'geo-42');

      await tester.pumpWidget(
        _buildHarness(
          listId: 'list-1',
          listsStream: Stream.value([list]),
          itemsStream: Stream.value([]),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(ActionChip));
      await tester.pumpAndSettle();

      // After navigation the location detail stub screen should be visible.
      expect(find.text('Location Detail'), findsOneWidget);
    });

    testWidgets('shows Add Location chip when list has no geofenceId',
        (tester) async {
      final list = _makeList();

      await tester.pumpWidget(
        _buildHarness(
          listId: 'list-1',
          listsStream: Stream.value([list]),
          itemsStream: Stream.value([]),
        ),
      );
      await tester.pump();

      // An "Add Location" ActionChip is shown even without a geofenceId.
      expect(find.byType(ActionChip), findsOneWidget);
      expect(find.text('Add Location'), findsOneWidget);
    });
  });
}
