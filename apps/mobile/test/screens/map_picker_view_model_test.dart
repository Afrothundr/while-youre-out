import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whileyoureout/screens/map_picker/map_picker_view_model.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockTodoListRepository extends Mock implements TodoListRepository {}

class MockGeofenceRepository extends Mock implements GeofenceRepository {}

class MockGeofenceService extends Mock implements GeofenceService {}

class MockAssignLocationUseCase extends Mock implements AssignLocationUseCase {}

class MockRegisterGeofenceUseCase extends Mock
    implements RegisterGeofenceUseCase {}

class MockUnregisterGeofenceUseCase extends Mock
    implements UnregisterGeofenceUseCase {}

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
}
