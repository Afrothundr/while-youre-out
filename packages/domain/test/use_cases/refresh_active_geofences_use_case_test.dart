import 'package:domain/domain.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  late MockGeofenceRepository geofenceRepository;
  late MockGeofenceService geofenceService;
  late RefreshActiveGeofencesUseCase useCase;

  final createdAt = DateTime(2024);

  // Device is at (0.0, 0.0)
  const deviceLat = 0.0;
  const deviceLng = 0.0;

  /// Build a [GeofenceRegion] whose centre is approximately [distanceKm]
  /// kilometres due-north of the origin (0,0).
  /// One degree of latitude ≈ 111 km.
  GeofenceRegion regionAt(String id, double distanceKm) {
    return GeofenceRegion(
      id: id,
      latitude: distanceKm / 111.0,
      longitude: 0,
      radiusMeters: 200,
      createdAt: createdAt,
    );
  }

  setUp(() {
    geofenceRepository = MockGeofenceRepository();
    geofenceService = MockGeofenceService();
    useCase = RefreshActiveGeofencesUseCase(
      geofenceRepository,
      geofenceService,
    );

    registerFallbackValue(
      GeofenceRegion(
        id: 'fallback',
        latitude: 0,
        longitude: 0,
        radiusMeters: 100,
        createdAt: createdAt,
      ),
    );
  });

  group('RefreshActiveGeofencesUseCase', () {
    test(
        'with 25 geofences: registers 20 nearest, unregisters 5 farthest',
        () async {
      // Create 25 regions sorted by increasing distance from origin.
      // Ids "region-01" … "region-25"; region-01 is closest,
      // region-25 farthest.
      final regions = List.generate(
        25,
        (i) => regionAt(
          'region-${(i + 1).toString().padLeft(2, '0')}',
          (i + 1) * 10.0,
        ),
      );

      when(() => geofenceRepository.getAllActiveGeofences())
          .thenAnswer((_) async => regions);
      when(() => geofenceService.registerRegion(any()))
          .thenAnswer((_) async {});
      when(() => geofenceService.unregisterRegion(any()))
          .thenAnswer((_) async {});
      when(
        () => geofenceRepository.setGeofenceActive(
          any(),
          active: any(named: 'active'),
        ),
      ).thenAnswer((_) async {});

      await useCase(currentLat: deviceLat, currentLng: deviceLng);

      // The 20 nearest regions (region-01 … region-20) should be registered.
      for (var i = 1; i <= 20; i++) {
        final id = 'region-${i.toString().padLeft(2, '0')}';
        verify(
          () => geofenceService.registerRegion(
            any(
              that: isA<GeofenceRegion>().having((r) => r.id, 'id', id),
            ),
          ),
        ).called(1);
      }

      // The 5 farthest regions (region-21 … region-25) should be unregistered.
      for (var i = 21; i <= 25; i++) {
        final id = 'region-${i.toString().padLeft(2, '0')}';
        verify(() => geofenceService.unregisterRegion(id)).called(1);
        verify(
          () => geofenceRepository.setGeofenceActive(id, active: false),
        ).called(1);
      }

      // After individual verifications the counts should be fully consumed.
      verifyNoMoreInteractions(geofenceService);
    });

    test('with exactly 20 geofences: registers all, unregisters none',
        () async {
      final regions = List.generate(
        20,
        (i) => regionAt('r-$i', (i + 1) * 5.0),
      );

      when(() => geofenceRepository.getAllActiveGeofences())
          .thenAnswer((_) async => regions);
      when(() => geofenceService.registerRegion(any()))
          .thenAnswer((_) async {});

      await useCase(currentLat: deviceLat, currentLng: deviceLng);

      verify(() => geofenceService.registerRegion(any())).called(20);
      verifyNever(() => geofenceService.unregisterRegion(any()));
      verifyNever(
        () => geofenceRepository.setGeofenceActive(
          any(),
          active: any(named: 'active'),
        ),
      );
    });

    test('with fewer than 20 geofences: registers all', () async {
      final regions = List.generate(
        5,
        (i) => regionAt('r-$i', (i + 1) * 2.0),
      );

      when(() => geofenceRepository.getAllActiveGeofences())
          .thenAnswer((_) async => regions);
      when(() => geofenceService.registerRegion(any()))
          .thenAnswer((_) async {});

      await useCase(currentLat: deviceLat, currentLng: deviceLng);

      verify(() => geofenceService.registerRegion(any())).called(5);
      verifyNever(() => geofenceService.unregisterRegion(any()));
    });

    test('with no geofences: does nothing', () async {
      when(() => geofenceRepository.getAllActiveGeofences())
          .thenAnswer((_) async => []);

      await useCase(currentLat: deviceLat, currentLng: deviceLng);

      verifyNever(() => geofenceService.registerRegion(any()));
      verifyNever(() => geofenceService.unregisterRegion(any()));
    });

    test('registers the nearest regions regardless of input order', () async {
      // Provide regions in reverse distance order to verify sorting.
      final regions = [
        regionAt('far', 200),
        regionAt('near', 10),
        regionAt('medium', 100),
      ];

      when(() => geofenceRepository.getAllActiveGeofences())
          .thenAnswer((_) async => regions);
      when(() => geofenceService.registerRegion(any()))
          .thenAnswer((_) async {});

      await useCase(currentLat: deviceLat, currentLng: deviceLng);

      // All 3 are within the 20-region cap so all should be registered.
      verify(() => geofenceService.registerRegion(any())).called(3);
      verifyNever(() => geofenceService.unregisterRegion(any()));
    });
  });
}
