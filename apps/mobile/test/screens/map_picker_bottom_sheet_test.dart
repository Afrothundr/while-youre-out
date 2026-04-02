import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whileyoureout/providers/providers.dart';
import 'package:whileyoureout/screens/map_picker/map_picker_bottom_sheet.dart';
import 'package:whileyoureout/screens/map_picker/map_picker_view_model.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockTodoListRepository extends Mock implements TodoListRepository {}

class MockGeofenceRepository extends Mock implements GeofenceRepository {}

class MockGeofenceService extends Mock implements GeofenceService {}

// ---------------------------------------------------------------------------
// Spy view-model
//
// Subclasses MapPickerViewModel to record calls to saveLocation and
// removeLocation without executing real database or platform-channel
// operations.  Tests inspect saveLocationListIds / removeLocationListIds
// to verify the correct listId was passed.
// ---------------------------------------------------------------------------

class _SpyViewModel extends MapPickerViewModel {
  final List<String> saveLocationListIds = [];
  final List<String> removeLocationListIds = [];

  @override
  Future<void> saveLocation({
    required String listId,
    required AssignLocationUseCase assignLocation,
    required RegisterGeofenceUseCase registerGeofence,
    required TodoListRepository listRepo,
  }) async {
    saveLocationListIds.add(listId);
  }

  @override
  Future<void> removeLocation({
    required String listId,
    required TodoListRepository listRepo,
    required GeofenceRepository geofenceRepo,
    required UnregisterGeofenceUseCase unregisterGeofence,
  }) async {
    removeLocationListIds.add(listId);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns a minimal [TodoList] for testing.
TodoList _makeList({
  String id = 'list-1',
  String? geofenceId,
}) =>
    TodoList(
      id: id,
      title: 'Groceries',
      geofenceId: geofenceId,
      sortOrder: 0,
      createdAt: DateTime(2024),
    );

/// Wraps the [testPage] widget in a [ProviderScope] + [MaterialApp.router]
/// with a two-level GoRouter hierarchy so that `context.pop()` (called by
/// [MapPickerBottomSheet] and [MapPickerRemoveButton] after save/remove)
/// can navigate back without triggering a GoRouter assertion.
///
/// [GoRouter] starts at `/parent/test`, which places `/parent` as the
/// implicit parent page in the navigation stack.
Widget _buildHarness({
  required Widget Function() testPage,
  required MockTodoListRepository listRepo,
}) {
  final geofenceRepo = MockGeofenceRepository();
  final geofenceService = MockGeofenceService();

  return ProviderScope(
    overrides: [
      todoListRepositoryProvider.overrideWithValue(listRepo),
      geofenceRepositoryProvider.overrideWithValue(geofenceRepo),
      geofenceServiceProvider.overrideWithValue(geofenceService),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/parent/test',
        routes: [
          GoRoute(
            path: '/parent',
            builder: (_, __) => const Scaffold(body: Text('Parent')),
            routes: [
              GoRoute(
                path: 'test',
                builder: (_, __) => Scaffold(body: testPage()),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Reusable finders
// ---------------------------------------------------------------------------

/// Finds the FilledButton that contains the 'Save Location' label.
///
/// Uses `find.byWidgetPredicate` with `is FilledButton` so that private
/// subclasses created by the `FilledButton.icon` factory are also matched,
/// unlike the strict `runtimeType ==` check in `find.byType`.
Finder get _saveButtonFinder => find.ancestor(
      of: find.text('Save Location'),
      matching: find.byWidgetPredicate((w) => w is FilledButton),
    );

/// Finds the OutlinedButton that contains the 'Remove Location' label.
Finder get _removeButtonFinder => find.ancestor(
      of: find.text('Remove Location'),
      matching: find.byWidgetPredicate((w) => w is OutlinedButton),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // MapPickerBottomSheet — Save button state and behaviour
  // =========================================================================

  group('MapPickerBottomSheet — Save button', () {
    // -----------------------------------------------------------------------
    // 1 — disabled when no pin has been placed
    // -----------------------------------------------------------------------

    testWidgets('is disabled when selectedLatLng is null', (tester) async {
      final listRepo = MockTodoListRepository();
      when(() => listRepo.watchAllLists())
          .thenAnswer((_) => Stream.value([_makeList()]));

      // selectedLatLng defaults to null in MapPickerViewModel.
      final vm = _SpyViewModel();
      addTearDown(vm.dispose);

      await tester.pumpWidget(
        _buildHarness(
          testPage: () => MapPickerBottomSheet(
            listId: 'list-1',
            viewModel: vm,
            // Use 0.6 (the maxChildSize) so all sheet content is visible
            // without needing to drag the sheet open.
            initialChildSize: 0.6,
          ),
          listRepo: listRepo,
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(_saveButtonFinder);
      expect(
        button.onPressed,
        isNull,
        reason: 'Save should be disabled when no pin is placed',
      );
    });

    // -----------------------------------------------------------------------
    // 2 — disabled while isSaving is true (shows spinner)
    // -----------------------------------------------------------------------

    testWidgets(
        'is disabled and shows a CircularProgressIndicator when isSaving',
        (tester) async {
      final listRepo = MockTodoListRepository();
      when(() => listRepo.watchAllLists())
          .thenAnswer((_) => Stream.value([_makeList()]));

      final vm = _SpyViewModel()
        ..selectedLatLng = const LatLng(37, -122)
        ..isSaving = true;
      addTearDown(vm.dispose);

      await tester.pumpWidget(
        _buildHarness(
          testPage: () => MapPickerBottomSheet(
            listId: 'list-1',
            viewModel: vm,
            initialChildSize: 0.6,
          ),
          listRepo: listRepo,
        ),
      );
      // Cannot use pumpAndSettle here: CircularProgressIndicator schedules
      // frames indefinitely and pumpAndSettle would time out.  Pump enough
      // time for the route transition to complete (approx 300 ms).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final button = tester.widget<FilledButton>(_saveButtonFinder);
      expect(
        button.onPressed,
        isNull,
        reason: 'Save should be disabled while isSaving is true',
      );
      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
        reason: 'A spinner should replace the save icon while saving',
      );
    });

    // -----------------------------------------------------------------------
    // 3 — enabled when a pin is placed and not saving
    // -----------------------------------------------------------------------

    testWidgets('is enabled when selectedLatLng is set and isSaving is false',
        (tester) async {
      final listRepo = MockTodoListRepository();
      when(() => listRepo.watchAllLists())
          .thenAnswer((_) => Stream.value([_makeList()]));

      final vm = _SpyViewModel()..selectedLatLng = const LatLng(37, -122);
      addTearDown(vm.dispose);

      await tester.pumpWidget(
        _buildHarness(
          testPage: () => MapPickerBottomSheet(
            listId: 'list-1',
            viewModel: vm,
            initialChildSize: 0.6,
          ),
          listRepo: listRepo,
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(_saveButtonFinder);
      expect(
        button.onPressed,
        isNotNull,
        reason: 'Save should be enabled when a pin is placed and not saving',
      );
    });

    // -----------------------------------------------------------------------
    // 4 — tapping Save calls viewModel.saveLocation with the correct listId
    // -----------------------------------------------------------------------

    testWidgets('tapping Save calls viewModel.saveLocation with the listId',
        (tester) async {
      final listRepo = MockTodoListRepository();
      when(() => listRepo.watchAllLists())
          .thenAnswer((_) => Stream.value([_makeList()]));

      final vm = _SpyViewModel()..selectedLatLng = const LatLng(37, -122);
      addTearDown(vm.dispose);

      await tester.pumpWidget(
        _buildHarness(
          testPage: () => MapPickerBottomSheet(
            listId: 'list-1',
            viewModel: vm,
            initialChildSize: 0.6,
          ),
          listRepo: listRepo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(_saveButtonFinder);
      // One pump to complete the spy's saveLocation Future and resume _onSave.
      await tester.pump();

      expect(
        vm.saveLocationListIds,
        ['list-1'],
        reason: 'saveLocation should have been called exactly once with '
            'listId "list-1"',
      );
    });

    // -----------------------------------------------------------------------
    // 5 — SnackBar 'Location saved' appears after a successful save
    // -----------------------------------------------------------------------

    testWidgets("shows a 'Location saved' SnackBar after saving",
        (tester) async {
      final listRepo = MockTodoListRepository();
      when(() => listRepo.watchAllLists())
          .thenAnswer((_) => Stream.value([_makeList()]));

      final vm = _SpyViewModel()..selectedLatLng = const LatLng(37, -122);
      addTearDown(vm.dispose);

      await tester.pumpWidget(
        _buildHarness(
          testPage: () => MapPickerBottomSheet(
            listId: 'list-1',
            viewModel: vm,
            initialChildSize: 0.6,
          ),
          listRepo: listRepo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(_saveButtonFinder);
      // First pump: resolves the saveLocation Future and calls showSnackBar.
      await tester.pump();
      // Second pump: renders the SnackBar widget into the tree.
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.text('Location saved'),
        findsOneWidget,
        reason: "'Location saved' SnackBar should be visible after a "
            'successful save',
      );
    });
  });

  // =========================================================================
  // MapPickerRemoveButton — visibility and behaviour
  // =========================================================================

  group('MapPickerRemoveButton', () {
    // -----------------------------------------------------------------------
    // 6 — hidden when the list has no geofenceId
    // -----------------------------------------------------------------------

    testWidgets('is absent when the list has no geofenceId', (tester) async {
      final listRepo = MockTodoListRepository();
      // No geofenceId → StreamProvider emits a list without a geofence.
      when(() => listRepo.watchAllLists())
          .thenAnswer((_) => Stream.value([_makeList()]));

      final vm = _SpyViewModel();
      addTearDown(vm.dispose);

      await tester.pumpWidget(
        _buildHarness(
          testPage: () => MapPickerRemoveButton(
            listId: 'list-1',
            viewModel: vm,
          ),
          listRepo: listRepo,
        ),
      );
      // pumpAndSettle lets the StreamProvider emit and the widget rebuild.
      await tester.pumpAndSettle();

      expect(
        _removeButtonFinder,
        findsNothing,
        reason: 'Remove Location button should not appear when the list has '
            'no geofenceId',
      );
    });

    // -----------------------------------------------------------------------
    // 7 — visible when the list has a geofenceId
    // -----------------------------------------------------------------------

    testWidgets('is present when the list has a geofenceId', (tester) async {
      final listRepo = MockTodoListRepository();
      when(() => listRepo.watchAllLists())
          .thenAnswer((_) => Stream.value([_makeList(geofenceId: 'geo-1')]));

      final vm = _SpyViewModel();
      addTearDown(vm.dispose);

      await tester.pumpWidget(
        _buildHarness(
          testPage: () => MapPickerRemoveButton(
            listId: 'list-1',
            viewModel: vm,
          ),
          listRepo: listRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        _removeButtonFinder,
        findsOneWidget,
        reason: 'Remove Location button should appear when the list has a '
            'geofenceId',
      );
    });

    // -----------------------------------------------------------------------
    // 8 — tapping Remove calls viewModel.removeLocation
    // -----------------------------------------------------------------------

    testWidgets('tapping Remove calls viewModel.removeLocation',
        (tester) async {
      final listRepo = MockTodoListRepository();
      when(() => listRepo.watchAllLists())
          .thenAnswer((_) => Stream.value([_makeList(geofenceId: 'geo-1')]));

      final vm = _SpyViewModel();
      addTearDown(vm.dispose);

      await tester.pumpWidget(
        _buildHarness(
          testPage: () => MapPickerRemoveButton(
            listId: 'list-1',
            viewModel: vm,
          ),
          listRepo: listRepo,
        ),
      );
      // pumpAndSettle lets the StreamProvider emit so the button appears.
      await tester.pumpAndSettle();

      await tester.tap(_removeButtonFinder);
      // One pump to complete the spy's removeLocation Future and resume
      // _onRemove.
      await tester.pump();

      expect(
        vm.removeLocationListIds,
        ['list-1'],
        reason: 'removeLocation should have been called exactly once with '
            'listId "list-1"',
      );
    });
  });
}
