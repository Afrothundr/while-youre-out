import 'package:domain/domain.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  late MockTodoListRepository listRepository;
  late MockGeofenceRepository geofenceRepository;
  late AssignLocationUseCase useCase;

  final createdAt = DateTime(2024);

  setUp(() {
    listRepository = MockTodoListRepository();
    geofenceRepository = MockGeofenceRepository();
    useCase = AssignLocationUseCase(listRepository, geofenceRepository);

    registerFallbackValue(
      TodoList(
        id: 'fallback',
        title: 'fallback',
        sortOrder: 0,
        createdAt: createdAt,
      ),
    );
    registerFallbackValue(
      GeofenceRegion(
        id: 'fallback-region',
        latitude: 0,
        longitude: 0,
        radiusMeters: 100,
        createdAt: createdAt,
      ),
    );
  });

  group('AssignLocationUseCase', () {
    test('saves a new GeofenceRegion and updates list.geofenceId when list has '
        'no existing geofenceId', () async {
      const listId = 'list-1';
      final list = TodoList(
        id: listId,
        title: 'My List',
        sortOrder: 0,
        createdAt: createdAt,
      );

      when(() => listRepository.getListById(listId))
          .thenAnswer((_) async => list);
      when(() => geofenceRepository.saveGeofence(any()))
          .thenAnswer((_) async {});
      when(() => listRepository.saveList(any())).thenAnswer((_) async {});

      await useCase(
        listId: listId,
        lat: 37.7749,
        lng: -122.4194,
        radiusMeters: 300,
        label: 'Office',
      );

      // GeofenceRegion should have been saved with the correct coords.
      final capturedRegion =
          verify(() => geofenceRepository.saveGeofence(captureAny()))
              .captured
              .single as GeofenceRegion;
      expect(capturedRegion.latitude, equals(37.7749));
      expect(capturedRegion.longitude, equals(-122.4194));
      expect(capturedRegion.radiusMeters, equals(300));
      expect(capturedRegion.label, equals('Office'));
      expect(capturedRegion.id, isNotEmpty);

      // The list should have been saved with the new geofenceId.
      final capturedList =
          verify(() => listRepository.saveList(captureAny())).captured.single
              as TodoList;
      expect(capturedList.geofenceId, equals(capturedRegion.id));
    });

    test('reuses existing geofenceId when list already has one', () async {
      const listId = 'list-2';
      const existingGeoId = 'existing-geo-id';

      final list = TodoList(
        id: listId,
        title: 'Existing Geo List',
        geofenceId: existingGeoId,
        sortOrder: 0,
        createdAt: createdAt,
      );

      when(() => listRepository.getListById(listId))
          .thenAnswer((_) async => list);
      when(() => geofenceRepository.saveGeofence(any()))
          .thenAnswer((_) async {});

      await useCase(
        listId: listId,
        lat: 40.7128,
        lng: -74.0060,
        radiusMeters: 500,
      );

      final capturedRegion =
          verify(() => geofenceRepository.saveGeofence(captureAny()))
              .captured
              .single as GeofenceRegion;
      expect(capturedRegion.id, equals(existingGeoId));

      // saveList should NOT be called because geofenceId already set.
      verifyNever(() => listRepository.saveList(any()));
    });

    test('enforces minimum radius of 100 m when a smaller value is provided',
        () async {
      const listId = 'list-3';
      final list = TodoList(
        id: listId,
        title: 'Small Radius List',
        sortOrder: 0,
        createdAt: createdAt,
      );

      when(() => listRepository.getListById(listId))
          .thenAnswer((_) async => list);
      when(() => geofenceRepository.saveGeofence(any()))
          .thenAnswer((_) async {});
      when(() => listRepository.saveList(any())).thenAnswer((_) async {});

      await useCase(
        listId: listId,
        lat: 51.5074,
        lng: -0.1278,
        radiusMeters: 50, // below minimum
      );

      final capturedRegion =
          verify(() => geofenceRepository.saveGeofence(captureAny()))
              .captured
              .single as GeofenceRegion;
      expect(capturedRegion.radiusMeters, equals(100));
    });

    test('does nothing when list is not found', () async {
      when(() => listRepository.getListById(any()))
          .thenAnswer((_) async => null);

      await useCase(
        listId: 'nonexistent',
        lat: 0,
        lng: 0,
        radiusMeters: 200,
      );

      verifyNever(() => geofenceRepository.saveGeofence(any()));
      verifyNever(() => listRepository.saveList(any()));
    });
  });
}
