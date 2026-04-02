import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whileyoureout/providers/providers.dart';
import 'package:whileyoureout/screens/map_picker/map_picker_view_model.dart';
import 'package:whileyoureout/screens/map_picker/search_bar_with_suggestions.dart';
import 'package:whileyoureout/services/places_autocomplete_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockPlacesAutocompleteService extends Mock
    implements PlacesAutocompleteService {}

// ---------------------------------------------------------------------------
// Spy view-model
//
// Subclasses MapPickerViewModel to count calls to clearAutocompleteSuggestions
// and to intercept selectPrediction (returning a stubbed LatLng without
// hitting the network).
// ---------------------------------------------------------------------------

class _SpyViewModel extends MapPickerViewModel {
  int clearSuggestionsCount = 0;
  final List<AutocompletePrediction> selectPredictionCalls = [];
  LatLng? _nextSelectResult;

  // ignore: use_setters_to_change_properties
  void stubSelectPrediction(LatLng? result) => _nextSelectResult = result;

  @override
  void clearAutocompleteSuggestions() {
    clearSuggestionsCount++;
    super.clearAutocompleteSuggestions();
  }

  /// Overrides the debounced implementation so no `Timer` is started during
  /// tests.  State is updated synchronously; callers can set
  /// `autocompleteSuggestions` directly to control what the widget renders.
  @override
  void updateSearchQuery(
    String query, {
    required PlacesAutocompleteService service,
    double? lat,
    double? lng,
  }) {
    if (query.trim().isEmpty) {
      autocompleteSuggestions = [];
      isLoadingAutocomplete = false;
    }
    notifyListeners();
  }

  @override
  Future<LatLng?> selectPrediction(
    AutocompletePrediction prediction, {
    required PlacesAutocompleteService service,
  }) async {
    selectPredictionCalls.add(prediction);
    // Mirror the real implementation: clear suggestions and notify listeners
    // so the wrapper rebuilds the widget under test.
    autocompleteSuggestions = [];
    isLoadingAutocomplete = false;
    notifyListeners();
    return _nextSelectResult;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AutocompletePrediction _makePrediction({
  String placeId = 'place-1',
  String mainText = 'Coffee Shop',
  String description = 'Coffee Shop, Market Street, San Francisco',
}) =>
    AutocompletePrediction(
      placeId: placeId,
      mainText: mainText,
      description: description,
    );

/// Listens to a [ChangeNotifier] and rebuilds its subtree on every
/// notification, mirroring the role that the parent `ConsumerWidget` plays in
/// the production `MapPickerScreen`.
class _NotifierWrapper extends StatefulWidget {
  const _NotifierWrapper({
    required this.notifier,
    required this.builder,
  });

  final ChangeNotifier notifier;
  final WidgetBuilder builder;

  @override
  State<_NotifierWrapper> createState() => _NotifierWrapperState();
}

class _NotifierWrapperState extends State<_NotifierWrapper> {
  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.notifier.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// Wraps [SearchBarWithSuggestions] in a [ProviderScope] + [MaterialApp] so it
/// can be pumped in isolation without a real database or map layer.
Widget _buildHarness({
  required _SpyViewModel viewModel,
  MockPlacesAutocompleteService? autocompleteService,
  LatLng locationBias = const LatLng(37.7749, -122.4194),
  void Function(LatLng)? onMoveCamera,
}) {
  final service = autocompleteService ?? MockPlacesAutocompleteService();
  return ProviderScope(
    overrides: [
      placesAutocompleteServiceProvider.overrideWithValue(service),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: _NotifierWrapper(
          notifier: viewModel,
          builder: (_) => SearchBarWithSuggestions(
            viewModel: viewModel,
            locationBias: locationBias,
            onMoveCamera: onMoveCamera ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SearchBarWithSuggestions', () {
    // -----------------------------------------------------------------------
    // 1 — Hint text
    // -----------------------------------------------------------------------

    testWidgets('renders search field with hint text', (tester) async {
      final vm = _SpyViewModel();
      addTearDown(vm.dispose);

      await tester.pumpWidget(_buildHarness(viewModel: vm));

      expect(find.byType(TextField), findsOneWidget);
      // Hint text is visible when the field is empty and unfocused.
      expect(
        find.descendant(
          of: find.byType(TextField),
          matching: find.text('Search for a place\u2026'),
        ),
        findsOneWidget,
      );
    });

    // -----------------------------------------------------------------------
    // 2 — Clear-button visibility
    // -----------------------------------------------------------------------

    testWidgets('clear button is hidden when the field is empty',
        (tester) async {
      final vm = _SpyViewModel();
      addTearDown(vm.dispose);

      await tester.pumpWidget(_buildHarness(viewModel: vm));

      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('clear button appears after text is entered', (tester) async {
      final vm = _SpyViewModel();
      addTearDown(vm.dispose);

      await tester.pumpWidget(_buildHarness(viewModel: vm));
      await tester.enterText(find.byType(TextField), 'coffee');
      await tester.pump();

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 3 — Tapping the clear button
    // -----------------------------------------------------------------------

    testWidgets(
        'tapping clear button empties the field and calls '
        'clearAutocompleteSuggestions', (tester) async {
      final vm = _SpyViewModel();
      addTearDown(vm.dispose);

      await tester.pumpWidget(_buildHarness(viewModel: vm));
      await tester.enterText(find.byType(TextField), 'coffee');
      await tester.pump();

      expect(find.byIcon(Icons.clear), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // Field should be cleared and the clear button should disappear.
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        isEmpty,
      );
      expect(find.byIcon(Icons.clear), findsNothing);
      // clearAutocompleteSuggestions must have been called at least once.
      // (_onClear always calls it; _onFocusChange may add a second call if
      // the unfocus also fires the listener.)
      expect(vm.clearSuggestionsCount, greaterThanOrEqualTo(1));
    });

    // -----------------------------------------------------------------------
    // 4 — Suggestions Card visible when list is non-empty
    // -----------------------------------------------------------------------

    testWidgets(
        'suggestions Card shows when autocompleteSuggestions is non-empty',
        (tester) async {
      final vm = _SpyViewModel()
        ..autocompleteSuggestions = [_makePrediction()];
      addTearDown(vm.dispose);

      await tester.pumpWidget(_buildHarness(viewModel: vm));

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Coffee Shop'), findsOneWidget);
    });

    testWidgets('suggestions Card renders one row per prediction',
        (tester) async {
      final vm = _SpyViewModel()
        ..autocompleteSuggestions = [
          _makePrediction(placeId: 'p1'),
          _makePrediction(
            placeId: 'p2',
            mainText: 'Tea House',
            description: 'Tea House, Mission District',
          ),
        ];
      addTearDown(vm.dispose);

      await tester.pumpWidget(_buildHarness(viewModel: vm));

      expect(find.text('Coffee Shop'), findsOneWidget);
      expect(find.text('Tea House'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 5 — Suggestions Card hidden when list is empty
    // -----------------------------------------------------------------------

    testWidgets(
        'suggestions Card is absent when autocompleteSuggestions is empty',
        (tester) async {
      final vm = _SpyViewModel(); // autocompleteSuggestions defaults to []
      addTearDown(vm.dispose);

      await tester.pumpWidget(_buildHarness(viewModel: vm));

      expect(find.byType(Card), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 6 — Tapping a suggestion
    // -----------------------------------------------------------------------

    testWidgets(
        'tapping a suggestion calls selectPrediction and onMoveCamera',
        (tester) async {
      const expectedLatLng = LatLng(37.7749, -122.4194);
      final prediction = _makePrediction();
      final vm = _SpyViewModel()
        ..autocompleteSuggestions = [prediction]
        ..stubSelectPrediction(expectedLatLng);
      addTearDown(vm.dispose);

      LatLng? capturedLatLng;

      await tester.pumpWidget(
        _buildHarness(
          viewModel: vm,
          onMoveCamera: (latLng) => capturedLatLng = latLng,
        ),
      );

      await tester.tap(find.text('Coffee Shop'));
      await tester.pumpAndSettle();

      expect(vm.selectPredictionCalls, hasLength(1));
      expect(vm.selectPredictionCalls.first.placeId, 'place-1');
      expect(capturedLatLng, expectedLatLng);
    });

    testWidgets(
        'tapping a suggestion does NOT call onMoveCamera when '
        'selectPrediction returns null', (tester) async {
      final prediction = _makePrediction();
      // stubSelectPrediction not called → _nextSelectResult is null by default
      final vm = _SpyViewModel()..autocompleteSuggestions = [prediction];
      addTearDown(vm.dispose);

      var moveCameraCallCount = 0;

      await tester.pumpWidget(
        _buildHarness(
          viewModel: vm,
          onMoveCamera: (_) => moveCameraCallCount++,
        ),
      );

      await tester.tap(find.text('Coffee Shop'));
      await tester.pumpAndSettle();

      expect(vm.selectPredictionCalls, hasLength(1));
      expect(moveCameraCallCount, 0);
    });

    testWidgets('tapping a suggestion hides the suggestions Card',
        (tester) async {
      final vm = _SpyViewModel()
        ..autocompleteSuggestions = [_makePrediction()]
        ..stubSelectPrediction(const LatLng(37, -122));
      addTearDown(vm.dispose);

      await tester.pumpWidget(_buildHarness(viewModel: vm));
      expect(find.byType(Card), findsOneWidget);

      await tester.tap(find.text('Coffee Shop'));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 7 — Loading spinner in prefix icon
    // -----------------------------------------------------------------------

    testWidgets(
        'loading spinner replaces the search icon when '
        'isLoadingAutocomplete is true', (tester) async {
      final vm = _SpyViewModel()..isLoadingAutocomplete = true;
      addTearDown(vm.dispose);

      await tester.pumpWidget(_buildHarness(viewModel: vm));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.search), findsNothing);
    });

    testWidgets(
        'search icon shows and no spinner when isLoadingAutocomplete '
        'is false', (tester) async {
      final vm = _SpyViewModel(); // isLoadingAutocomplete defaults to false
      addTearDown(vm.dispose);

      await tester.pumpWidget(_buildHarness(viewModel: vm));

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 8 — Focus loss clears suggestions
    // -----------------------------------------------------------------------

    testWidgets('losing focus calls clearAutocompleteSuggestions',
        (tester) async {
      final vm = _SpyViewModel();
      addTearDown(vm.dispose);

      await tester.pumpWidget(_buildHarness(viewModel: vm));

      // Tap the field to acquire focus.
      await tester.tap(find.byType(TextField));
      await tester.pump();

      final countBeforeUnfocus = vm.clearSuggestionsCount;

      // Remove focus (simulates the user tapping elsewhere on the screen).
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      expect(
        vm.clearSuggestionsCount,
        greaterThan(countBeforeUnfocus),
        reason:
            'clearAutocompleteSuggestions should be called when focus is lost',
      );
    });
  });
}
