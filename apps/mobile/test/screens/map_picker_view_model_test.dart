import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whileyoureout/screens/map_picker/map_picker_view_model.dart';
import 'package:whileyoureout/services/places_autocomplete_service.dart';
import 'package:whileyoureout/services/places_suggestion_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockTodoListRepository extends Mock implements TodoListRepository {}

class MockGeofenceRepository extends Mock implements GeofenceRepository {}

class MockGeofenceService extends Mock implements GeofenceService {}

class MockAssignLocationUseCase extends Mock implements AssignLocationUseCase {}

class MockRegisterGeofenceUseCase extends Mock
    implements RegisterGeofenceUseCase {}

class MockPlacesSuggestionService extends Mock
    implements PlacesSuggestionService {}

class MockUnregisterGeofenceUseCase extends Mock
    implements UnregisterGeofenceUseCase {}

class MockPlacesAutocompleteService extends Mock
    implements PlacesAutocompleteService {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

TodoList _makeList({
  String id = 'list-1',
  String? geofenceId,
}) {
  return TodoList(
    id: id,
    title: 'Groceries',
    sortOrder: 0,
    createdAt: DateTime(2024),
    geofenceId: geofenceId,
  );
}

GeofenceRegion _makeRegion({String id = 'geo-1'}) {
  return GeofenceRegion(
    id: id,
    latitude: 37.7749,
    longitude: -122.4194,
    radiusMeters: 300,
    label: 'Home',
    createdAt: DateTime(2024),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(
      GeofenceRegion(
        id: 'fallback',
        latitude: 0,
        longitude: 0,
        radiusMeters: 200,
        createdAt: DateTime(2024),
      ),
    );
    registerFallbackValue(
      TodoList(
        id: 'fallback',
        title: 'fallback',
        sortOrder: 0,
        createdAt: DateTime(2024),
      ),
    );
  });

  group('MapPickerViewModel', () {
    late MapPickerViewModel viewModel;

    setUp(() {
      viewModel = MapPickerViewModel();
    });

    tearDown(() {
      viewModel.dispose();
    });

    // -----------------------------------------------------------------------
    // selectLocation
    // -----------------------------------------------------------------------

    test('selectLocation updates selectedLatLng and notifies listeners', () {
      var notified = false;
      viewModel.addListener(() => notified = true);

      const latLng = LatLng(51.5074, -0.1278);
      viewModel.selectLocation(latLng);

      expect(viewModel.selectedLatLng, equals(latLng));
      expect(notified, isTrue);
    });

    test('selectLocation replaces a previously set pin', () {
      viewModel.selectLocation(const LatLng(0, 0));
      const newPin = LatLng(48.8566, 2.3522);
      viewModel.selectLocation(newPin);

      expect(viewModel.selectedLatLng, equals(newPin));
    });

    // -----------------------------------------------------------------------
    // updateRadius
    // -----------------------------------------------------------------------

    test('updateRadius updates radiusMeters and notifies listeners', () {
      var notified = false;
      void listener() => notified = true;
      viewModel.addListener(listener);
      addTearDown(() => viewModel.removeListener(listener));

      viewModel.updateRadius(500);

      expect(viewModel.radiusMeters, equals(500));
      expect(notified, isTrue);
    });

    // -----------------------------------------------------------------------
    // updateLabel
    // -----------------------------------------------------------------------

    test('updateLabel updates label and notifies listeners', () {
      var notified = false;
      void listener() => notified = true;
      viewModel.addListener(listener);
      addTearDown(() => viewModel.removeListener(listener));

      viewModel.updateLabel('Supermarket');

      expect(viewModel.label, equals('Supermarket'));
      expect(notified, isTrue);
    });

    // -----------------------------------------------------------------------
    // prefill
    // -----------------------------------------------------------------------

    test('prefill loads region values into the view-model', () {
      final region = _makeRegion();
      viewModel.prefill(region);

      expect(viewModel.selectedLatLng?.latitude, closeTo(37.7749, 0.0001));
      expect(viewModel.selectedLatLng?.longitude, closeTo(-122.4194, 0.0001));
      expect(viewModel.radiusMeters, equals(300));
      expect(viewModel.label, equals('Home'));
    });

    // -----------------------------------------------------------------------
    // saveLocation
    // -----------------------------------------------------------------------

    test('saveLocation does nothing when selectedLatLng is null', () async {
      final mockAssign = MockAssignLocationUseCase();
      final mockRegister = MockRegisterGeofenceUseCase();
      final mockListRepo = MockTodoListRepository();

      await viewModel.saveLocation(
        listId: 'list-1',
        assignLocation: mockAssign,
        registerGeofence: mockRegister,
        listRepo: mockListRepo,
      );

      verifyNever(
        () => mockAssign(
          listId: any(named: 'listId'),
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          radiusMeters: any(named: 'radiusMeters'),
        ),
      );
    });

    test(
      'saveLocation calls AssignLocationUseCase '
      'with correct args when pin is set',
      () async {
      const pin = LatLng(51.5074, -0.1278);
      viewModel
        ..selectLocation(pin)
        ..updateRadius(350)
        ..updateLabel('Office');

      final mockAssign = MockAssignLocationUseCase();
      final mockRegister = MockRegisterGeofenceUseCase();
      final mockListRepo = MockTodoListRepository();

      when(
        () => mockAssign(
          listId: any(named: 'listId'),
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          radiusMeters: any(named: 'radiusMeters'),
          label: any(named: 'label'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => mockListRepo.getListById(any()),
      ).thenAnswer((_) async => _makeList(geofenceId: 'geo-1'));

      when(() => mockRegister(any())).thenAnswer((_) async {});

      await viewModel.saveLocation(
        listId: 'list-1',
        assignLocation: mockAssign,
        registerGeofence: mockRegister,
        listRepo: mockListRepo,
      );

      verify(
        () => mockAssign(
          listId: 'list-1',
          lat: 51.5074,
          lng: -0.1278,
          radiusMeters: 350,
          label: 'Office',
        ),
      ).called(1);
    });

    test(
        'saveLocation calls RegisterGeofenceUseCase with geofenceId from list',
        () async {
      const pin = LatLng(51.5074, -0.1278);
      viewModel.selectLocation(pin);

      final mockAssign = MockAssignLocationUseCase();
      final mockRegister = MockRegisterGeofenceUseCase();
      final mockListRepo = MockTodoListRepository();

      when(
        () => mockAssign(
          listId: any(named: 'listId'),
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          radiusMeters: any(named: 'radiusMeters'),
          label: any(named: 'label'),
        ),
      ).thenAnswer((_) async {});

      when(() => mockListRepo.getListById('list-1'))
          .thenAnswer((_) async => _makeList(geofenceId: 'geo-42'));

      when(() => mockRegister(any())).thenAnswer((_) async {});

      await viewModel.saveLocation(
        listId: 'list-1',
        assignLocation: mockAssign,
        registerGeofence: mockRegister,
        listRepo: mockListRepo,
      );

      verify(() => mockRegister('geo-42')).called(1);
    });

    test(
      'saveLocation does not call RegisterGeofenceUseCase '
      'when list has no geofenceId',
      () async {
      const pin = LatLng(0, 0);
      viewModel.selectLocation(pin);

      final mockAssign = MockAssignLocationUseCase();
      final mockRegister = MockRegisterGeofenceUseCase();
      final mockListRepo = MockTodoListRepository();

      when(
        () => mockAssign(
          listId: any(named: 'listId'),
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          radiusMeters: any(named: 'radiusMeters'),
          label: any(named: 'label'),
        ),
      ).thenAnswer((_) async {});

      // List has no geofenceId yet.
      when(() => mockListRepo.getListById('list-1'))
          .thenAnswer((_) async => _makeList());

      await viewModel.saveLocation(
        listId: 'list-1',
        assignLocation: mockAssign,
        registerGeofence: mockRegister,
        listRepo: mockListRepo,
      );

      verifyNever(() => mockRegister(any()));
    });

    test('isSaving is false after saveLocation completes', () async {
      const pin = LatLng(0, 0);
      viewModel.selectLocation(pin);

      final mockAssign = MockAssignLocationUseCase();
      final mockRegister = MockRegisterGeofenceUseCase();
      final mockListRepo = MockTodoListRepository();

      when(
        () => mockAssign(
          listId: any(named: 'listId'),
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          radiusMeters: any(named: 'radiusMeters'),
          label: any(named: 'label'),
        ),
      ).thenAnswer((_) async {});

      when(() => mockListRepo.getListById(any()))
          .thenAnswer((_) async => _makeList());

      await viewModel.saveLocation(
        listId: 'list-1',
        assignLocation: mockAssign,
        registerGeofence: mockRegister,
        listRepo: mockListRepo,
      );

      expect(viewModel.isSaving, isFalse);
    });

    // -----------------------------------------------------------------------
    // removeLocation
    // -----------------------------------------------------------------------

    test('removeLocation calls UnregisterGeofenceUseCase with geofenceId',
        () async {
      final mockListRepo = MockTodoListRepository();
      final mockGeoRepo = MockGeofenceRepository();
      final mockUnregister = MockUnregisterGeofenceUseCase();

      when(() => mockListRepo.getListById('list-1'))
          .thenAnswer((_) async => _makeList(geofenceId: 'geo-99'));

      when(() => mockUnregister(any())).thenAnswer((_) async {});
      when(() => mockListRepo.saveList(any())).thenAnswer((_) async {});

      await viewModel.removeLocation(
        listId: 'list-1',
        listRepo: mockListRepo,
        geofenceRepo: mockGeoRepo,
        unregisterGeofence: mockUnregister,
      );

      verify(() => mockUnregister('geo-99')).called(1);
    });

    test('removeLocation clears geofenceId on the list', () async {
      final mockListRepo = MockTodoListRepository();
      final mockGeoRepo = MockGeofenceRepository();
      final mockUnregister = MockUnregisterGeofenceUseCase();

      final originalList = _makeList(geofenceId: 'geo-99');
      when(() => mockListRepo.getListById('list-1'))
          .thenAnswer((_) async => originalList);

      when(() => mockUnregister(any())).thenAnswer((_) async {});

      TodoList? savedList;
      when(() => mockListRepo.saveList(any())).thenAnswer((invocation) async {
        savedList = invocation.positionalArguments.first as TodoList;
      });

      await viewModel.removeLocation(
        listId: 'list-1',
        listRepo: mockListRepo,
        geofenceRepo: mockGeoRepo,
        unregisterGeofence: mockUnregister,
      );

      expect(savedList?.geofenceId, isNull);
    });

    test('removeLocation does nothing when list has no geofenceId', () async {
      final mockListRepo = MockTodoListRepository();
      final mockGeoRepo = MockGeofenceRepository();
      final mockUnregister = MockUnregisterGeofenceUseCase();

      when(() => mockListRepo.getListById('list-1'))
          .thenAnswer((_) async => _makeList());

      await viewModel.removeLocation(
        listId: 'list-1',
        listRepo: mockListRepo,
        geofenceRepo: mockGeoRepo,
        unregisterGeofence: mockUnregister,
      );

      verifyNever(() => mockUnregister(any()));
      verifyNever(() => mockListRepo.saveList(any()));
    });

    test('isSaving is false after removeLocation completes', () async {
      final mockListRepo = MockTodoListRepository();
      final mockGeoRepo = MockGeofenceRepository();
      final mockUnregister = MockUnregisterGeofenceUseCase();

      when(() => mockListRepo.getListById('list-1'))
          .thenAnswer((_) async => _makeList(geofenceId: 'geo-1'));

      when(() => mockUnregister(any())).thenAnswer((_) async {});
      when(() => mockListRepo.saveList(any())).thenAnswer((_) async {});

      await viewModel.removeLocation(
        listId: 'list-1',
        listRepo: mockListRepo,
        geofenceRepo: mockGeoRepo,
        unregisterGeofence: mockUnregister,
      );

      expect(viewModel.isSaving, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // autoSuggest
  // -------------------------------------------------------------------------

  group('MapPickerViewModel — autoSuggest', () {
    late MapPickerViewModel viewModel;

    setUp(() => viewModel = MapPickerViewModel());
    tearDown(() => viewModel.dispose());

    test(
      'tryAutoSuggestLocation sets autoSuggestion and pre-fills empty label',
      () async {
        final service = MockPlacesSuggestionService();
        when(
          () => service.findNearbyPlace(
            keyword: any(named: 'keyword'),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            radiusMeters: any(named: 'radiusMeters'),
          ),
        ).thenAnswer(
          (_) async => const PlaceSuggestion(
            name: 'Walmart',
            latitude: 37.77,
            longitude: -122.41,
            distanceMeters: 400,
          ),
        );

        await viewModel.tryAutoSuggestLocation(
          listTitle: 'Walmart',
          lat: 37.77,
          lng: -122.41,
          service: service,
        );

        expect(viewModel.autoSuggestion?.name, equals('Walmart'));
        expect(viewModel.label, equals('Walmart'));
      },
    );

    test(
      'tryAutoSuggestLocation does not overwrite '
      'a label the user already typed',
      () async {
        viewModel.updateLabel('My custom label');

        final service = MockPlacesSuggestionService();
        when(
          () => service.findNearbyPlace(
            keyword: any(named: 'keyword'),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            radiusMeters: any(named: 'radiusMeters'),
          ),
        ).thenAnswer(
          (_) async => const PlaceSuggestion(
            name: 'Target',
            latitude: 37.77,
            longitude: -122.41,
            distanceMeters: 300,
          ),
        );

        await viewModel.tryAutoSuggestLocation(
          listTitle: 'Target',
          lat: 37.77,
          lng: -122.41,
          service: service,
        );

        // autoSuggestion is set but the user's label is preserved.
        expect(viewModel.autoSuggestion?.name, equals('Target'));
        expect(viewModel.label, equals('My custom label'));
      },
    );

    test(
      'tryAutoSuggestLocation is a no-op when service returns null',
      () async {
        final service = MockPlacesSuggestionService();
        when(
          () => service.findNearbyPlace(
            keyword: any(named: 'keyword'),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            radiusMeters: any(named: 'radiusMeters'),
          ),
        ).thenAnswer((_) async => null);

        var notified = false;
        viewModel.addListener(() => notified = true);

        await viewModel.tryAutoSuggestLocation(
          listTitle: 'Nowhere',
          lat: 37.77,
          lng: -122.41,
          service: service,
        );

        expect(viewModel.autoSuggestion, isNull);
        expect(viewModel.label, isEmpty);
        expect(notified, isFalse);
      },
    );

    test(
      'dismissAutoSuggestion clears autoSuggestion and notifies listeners',
      () async {
        final service = MockPlacesSuggestionService();
        when(
          () => service.findNearbyPlace(
            keyword: any(named: 'keyword'),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            radiusMeters: any(named: 'radiusMeters'),
          ),
        ).thenAnswer(
          (_) async => const PlaceSuggestion(
            name: 'Costco',
            latitude: 37.77,
            longitude: -122.41,
            distanceMeters: 1200,
          ),
        );

        await viewModel.tryAutoSuggestLocation(
          listTitle: 'Costco',
          lat: 37.77,
          lng: -122.41,
          service: service,
        );

        expect(viewModel.autoSuggestion, isNotNull);

        var notified = false;
        viewModel
          ..addListener(() => notified = true)
          ..dismissAutoSuggestion();

        expect(viewModel.autoSuggestion, isNull);
        expect(notified, isTrue);
      },
    );

    test(
      'dismissAutoSuggestion does not clear the label',
      () async {
        final service = MockPlacesSuggestionService();
        when(
          () => service.findNearbyPlace(
            keyword: any(named: 'keyword'),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            radiusMeters: any(named: 'radiusMeters'),
          ),
        ).thenAnswer(
          (_) async => const PlaceSuggestion(
            name: 'Kroger',
            latitude: 37.77,
            longitude: -122.41,
            distanceMeters: 800,
          ),
        );

        await viewModel.tryAutoSuggestLocation(
          listTitle: 'Kroger',
          lat: 37.77,
          lng: -122.41,
          service: service,
        );

        expect(viewModel.label, equals('Kroger'));

        viewModel.dismissAutoSuggestion();

        expect(viewModel.autoSuggestion, isNull);
        expect(viewModel.label, equals('Kroger')); // label preserved
      },
    );
  });

  // -------------------------------------------------------------------------
  // tryAutoFillLabel
  // -------------------------------------------------------------------------

  group('MapPickerViewModel — tryAutoFillLabel', () {
    late MapPickerViewModel viewModel;

    setUp(() => viewModel = MapPickerViewModel());
    tearDown(() => viewModel.dispose());

    test(
      'tryAutoFillLabel sets label from reverse-geocoded place name '
      'when label is empty',
      () async {
        final service = MockPlacesAutocompleteService();
        when(() => service.reverseGeocode(any(), any()))
            .thenAnswer((_) async => 'Walmart Supercenter');

        await viewModel.tryAutoFillLabel(
          lat: 37.77,
          lng: -122.41,
          service: service,
        );

        expect(viewModel.label, equals('Walmart Supercenter'));
      },
    );

    test(
      'tryAutoFillLabel notifies listeners when label is updated',
      () async {
        final service = MockPlacesAutocompleteService();
        when(() => service.reverseGeocode(any(), any()))
            .thenAnswer((_) async => '123 Main St');

        var notified = false;
        viewModel.addListener(() => notified = true);

        await viewModel.tryAutoFillLabel(
          lat: 37.77,
          lng: -122.41,
          service: service,
        );

        expect(notified, isTrue);
      },
    );

    test(
      'tryAutoFillLabel is a no-op when label is already set',
      () async {
        viewModel.updateLabel('My custom label');

        final service = MockPlacesAutocompleteService();

        await viewModel.tryAutoFillLabel(
          lat: 37.77,
          lng: -122.41,
          service: service,
        );

        // reverseGeocode should never be called.
        verifyNever(() => service.reverseGeocode(any(), any()));
        expect(viewModel.label, equals('My custom label'));
      },
    );

    test(
      'tryAutoFillLabel is a no-op when service returns null',
      () async {
        final service = MockPlacesAutocompleteService();
        when(() => service.reverseGeocode(any(), any()))
            .thenAnswer((_) async => null);

        var notified = false;
        viewModel.addListener(() => notified = true);

        await viewModel.tryAutoFillLabel(
          lat: 37.77,
          lng: -122.41,
          service: service,
        );

        expect(viewModel.label, isEmpty);
        expect(notified, isFalse);
      },
    );

    test(
      'tryAutoFillLabel is a no-op when service returns empty string',
      () async {
        final service = MockPlacesAutocompleteService();
        when(() => service.reverseGeocode(any(), any()))
            .thenAnswer((_) async => '');

        await viewModel.tryAutoFillLabel(
          lat: 37.77,
          lng: -122.41,
          service: service,
        );

        expect(viewModel.label, isEmpty);
      },
    );

    test(
      'tryAutoFillLabel passes correct coordinates to service',
      () async {
        final service = MockPlacesAutocompleteService();
        when(() => service.reverseGeocode(any(), any()))
            .thenAnswer((_) async => 'CVS Pharmacy');

        await viewModel.tryAutoFillLabel(
          lat: 51.5074,
          lng: -0.1278,
          service: service,
        );

        verify(() => service.reverseGeocode(51.5074, -0.1278)).called(1);
      },
    );
  });

  // -------------------------------------------------------------------------
  // Autocomplete search bar
  // -------------------------------------------------------------------------

  group('MapPickerViewModel — autocomplete search', () {
    late MapPickerViewModel viewModel;

    setUp(() => viewModel = MapPickerViewModel());
    tearDown(() => viewModel.dispose());

    // -----------------------------------------------------------------------
    // updateSearchQuery — blank input
    // -----------------------------------------------------------------------

    test(
      'updateSearchQuery with blank input immediately clears suggestions '
      'without hitting the network',
      () async {
        final service = MockPlacesAutocompleteService();

        // Seed some suggestions first.
        viewModel.autocompleteSuggestions = [
          const AutocompletePrediction(
            placeId: 'p1',
            description: 'Walmart, SF',
            mainText: 'Walmart',
          ),
        ];

        var notified = false;
        viewModel
          ..addListener(() => notified = true)
          ..updateSearchQuery('', service: service);

        expect(viewModel.autocompleteSuggestions, isEmpty);
        expect(viewModel.isLoadingAutocomplete, isFalse);
        expect(notified, isTrue);

        // Network should never be called for blank input.
        verifyNever(
          () => service.getSuggestions(
            any(),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        );
      },
    );

    test(
      'updateSearchQuery with whitespace-only input immediately clears '
      'suggestions without hitting the network',
      () {
        final service = MockPlacesAutocompleteService();

        viewModel.updateSearchQuery('   ', service: service);

        expect(viewModel.autocompleteSuggestions, isEmpty);
        verifyNever(
          () => service.getSuggestions(
            any(),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        );
      },
    );

    // -----------------------------------------------------------------------
    // updateSearchQuery — debounced fetch
    // -----------------------------------------------------------------------

    test(
      'updateSearchQuery populates autocompleteSuggestions after debounce',
      () async {
        final service = MockPlacesAutocompleteService();
        when(
          () => service.getSuggestions(
            any(),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer(
          (_) async => [
            const AutocompletePrediction(
              placeId: 'place-1',
              description: 'Walmart Supercenter, Market St, San Francisco',
              mainText: 'Walmart Supercenter',
            ),
            const AutocompletePrediction(
              placeId: 'place-2',
              description: 'Walmart Neighborhood Market, 3rd St, SF',
              mainText: 'Walmart Neighborhood Market',
            ),
          ],
        );

        viewModel.updateSearchQuery(
          'Walmart',
          service: service,
          lat: 37.77,
          lng: -122.41,
        );

        // Before debounce fires, suggestions are still empty.
        expect(viewModel.autocompleteSuggestions, isEmpty);

        // Wait for debounce (300 ms) + network round-trip buffer.
        await Future<void>.delayed(const Duration(milliseconds: 400));

        expect(viewModel.autocompleteSuggestions, hasLength(2));
        expect(
          viewModel.autocompleteSuggestions.first.mainText,
          equals('Walmart Supercenter'),
        );
        expect(viewModel.isLoadingAutocomplete, isFalse);
      },
    );

    test(
      'updateSearchQuery cancels in-flight debounce when called again',
      () async {
        final service = MockPlacesAutocompleteService();
        var callCount = 0;
        when(
          () => service.getSuggestions(
            any(),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          return [];
        });

        // Rapid successive calls — only the last one should fire.
        viewModel
          ..updateSearchQuery('W', service: service)
          ..updateSearchQuery('Wa', service: service)
          ..updateSearchQuery('Wal', service: service);

        await Future<void>.delayed(const Duration(milliseconds: 400));

        expect(callCount, equals(1));
      },
    );

    // -----------------------------------------------------------------------
    // clearAutocompleteSuggestions
    // -----------------------------------------------------------------------

    test(
      'clearAutocompleteSuggestions resets state and notifies listeners',
      () {
        viewModel
          ..autocompleteSuggestions = [
            const AutocompletePrediction(
              placeId: 'p1',
              description: 'Target, SF',
              mainText: 'Target',
            ),
          ]
          ..isLoadingAutocomplete = true;

        var notified = false;
        viewModel
          ..addListener(() => notified = true)
          ..clearAutocompleteSuggestions();

        expect(viewModel.autocompleteSuggestions, isEmpty);
        expect(viewModel.isLoadingAutocomplete, isFalse);
        expect(notified, isTrue);
      },
    );

    // -----------------------------------------------------------------------
    // selectPrediction
    // -----------------------------------------------------------------------

    test(
      'selectPrediction sets selectedLatLng and label from place details',
      () async {
        final service = MockPlacesAutocompleteService();
        when(() => service.getPlaceDetails('place-1')).thenAnswer(
          (_) async => const PlaceSuggestion(
            name: 'Whole Foods Market',
            latitude: 37.79,
            longitude: -122.43,
            distanceMeters: 0,
          ),
        );

        const prediction = AutocompletePrediction(
          placeId: 'place-1',
          description: 'Whole Foods Market, California St, SF',
          mainText: 'Whole Foods Market',
        );

        final result = await viewModel.selectPrediction(
          prediction,
          service: service,
        );

        expect(result, isNotNull);
        expect(result!.latitude, closeTo(37.79, 0.0001));
        expect(result.longitude, closeTo(-122.43, 0.0001));
        expect(viewModel.selectedLatLng?.latitude, closeTo(37.79, 0.0001));
        expect(viewModel.label, equals('Whole Foods Market'));
        expect(viewModel.autocompleteSuggestions, isEmpty);
        expect(viewModel.isLoadingAutocomplete, isFalse);
      },
    );

    test(
      'selectPrediction uses prediction.mainText for label '
      'even when details.name differs',
      () async {
        final service = MockPlacesAutocompleteService();
        when(() => service.getPlaceDetails('place-2')).thenAnswer(
          (_) async => const PlaceSuggestion(
            name: 'CVS Pharmacy #12345',
            latitude: 37.78,
            longitude: -122.40,
            distanceMeters: 0,
          ),
        );

        const prediction = AutocompletePrediction(
          placeId: 'place-2',
          description: 'CVS Pharmacy, Mission St, SF',
          mainText: 'CVS Pharmacy',
        );

        await viewModel.selectPrediction(prediction, service: service);

        // mainText ('CVS Pharmacy') takes precedence over the full API name.
        expect(viewModel.label, equals('CVS Pharmacy'));
      },
    );

    test(
      'selectPrediction falls back to details.name when mainText is empty',
      () async {
        final service = MockPlacesAutocompleteService();
        when(() => service.getPlaceDetails('place-3')).thenAnswer(
          (_) async => const PlaceSuggestion(
            name: 'Home Depot',
            latitude: 37.75,
            longitude: -122.45,
            distanceMeters: 0,
          ),
        );

        const prediction = AutocompletePrediction(
          placeId: 'place-3',
          description: 'Home Depot, Colma, CA',
          mainText: '', // empty mainText
        );

        await viewModel.selectPrediction(prediction, service: service);

        expect(viewModel.label, equals('Home Depot'));
      },
    );

    test(
      'selectPrediction returns null and clears suggestions when '
      'getPlaceDetails fails',
      () async {
        final service = MockPlacesAutocompleteService();
        when(() => service.getPlaceDetails(any()))
            .thenAnswer((_) async => null);

        const prediction = AutocompletePrediction(
          placeId: 'bad-id',
          description: 'Unknown place',
          mainText: 'Unknown place',
        );

        // Seed some suggestions to confirm they are cleared regardless.
        viewModel.autocompleteSuggestions = [prediction];

        final result = await viewModel.selectPrediction(
          prediction,
          service: service,
        );

        expect(result, isNull);
        expect(viewModel.selectedLatLng, isNull);
        expect(viewModel.autocompleteSuggestions, isEmpty);
      },
    );

    test(
      'selectPrediction notifies listeners on success',
      () async {
        final service = MockPlacesAutocompleteService();
        when(() => service.getPlaceDetails(any())).thenAnswer(
          (_) async => const PlaceSuggestion(
            name: "Trader Joe's",
            latitude: 37.76,
            longitude: -122.42,
            distanceMeters: 0,
          ),
        );

        var notifyCount = 0;
        viewModel.addListener(() => notifyCount++);

        await viewModel.selectPrediction(
          const AutocompletePrediction(
            placeId: 'any-id',
            description: "Trader Joe's, SF",
            mainText: "Trader Joe's",
          ),
          service: service,
        );

        expect(notifyCount, greaterThan(0));
      },
    );
  });
}
