import 'package:domain/domain.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  late MockTodoListRepository listRepository;
  late MockTodoItemRepository itemRepository;
  late MockGeofenceRepository geofenceRepository;
  late MockGeofenceService geofenceService;
  late DeleteListUseCase useCase;

  final createdAt = DateTime(2024);

  setUp(() {
    listRepository = MockTodoListRepository();
    itemRepository = MockTodoItemRepository();
    geofenceRepository = MockGeofenceRepository();
    geofenceService = MockGeofenceService();

    useCase = DeleteListUseCase(
      listRepository,
      itemRepository,
      geofenceRepository,
      geofenceService,
    );

    registerFallbackValue(
      TodoList(
        id: 'fallback',
        title: 'fallback',
        sortOrder: 0,
        createdAt: createdAt,
      ),
    );
    registerFallbackValue(
      TodoItem(
        id: 'fallback-item',
        listId: 'fallback-list',
        title: 'fallback',
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

  group('DeleteListUseCase', () {
    test(
        'when list has geofenceId, calls unregisterRegion, deleteGeofence, '
        'and deleteList', () async {
      const listId = 'list-1';
      const geofenceId = 'geo-1';

      final list = TodoList(
        id: listId,
        title: 'My List',
        geofenceId: geofenceId,
        sortOrder: 0,
        createdAt: createdAt,
      );

      when(() => listRepository.getListById(listId))
          .thenAnswer((_) async => list);
      when(() => itemRepository.getItemsForList(listId))
          .thenAnswer((_) async => []);
      when(() => geofenceService.unregisterRegion(geofenceId))
          .thenAnswer((_) async {});
      when(() => geofenceRepository.deleteGeofence(geofenceId))
          .thenAnswer((_) async {});
      when(() => listRepository.deleteList(listId)).thenAnswer((_) async {});

      await useCase(listId);

      verify(() => geofenceService.unregisterRegion(geofenceId)).called(1);
      verify(() => geofenceRepository.deleteGeofence(geofenceId)).called(1);
      verify(() => listRepository.deleteList(listId)).called(1);
    });

    test('when list has no geofenceId, skips geofence steps', () async {
      const listId = 'list-2';

      final list = TodoList(
        id: listId,
        title: 'No Geo List',
        sortOrder: 0,
        createdAt: createdAt,
      );

      when(() => listRepository.getListById(listId))
          .thenAnswer((_) async => list);
      when(() => itemRepository.getItemsForList(listId))
          .thenAnswer((_) async => []);
      when(() => listRepository.deleteList(listId)).thenAnswer((_) async {});

      await useCase(listId);

      verifyNever(() => geofenceService.unregisterRegion(any()));
      verifyNever(() => geofenceRepository.deleteGeofence(any()));
      verify(() => listRepository.deleteList(listId)).called(1);
    });

    test('deletes all items belonging to the list', () async {
      const listId = 'list-3';

      final list = TodoList(
        id: listId,
        title: 'Has Items',
        sortOrder: 0,
        createdAt: createdAt,
      );

      final items = [
        TodoItem(
          id: 'item-1',
          listId: listId,
          title: 'Item 1',
          createdAt: createdAt,
        ),
        TodoItem(
          id: 'item-2',
          listId: listId,
          title: 'Item 2',
          createdAt: createdAt,
        ),
      ];

      when(() => listRepository.getListById(listId))
          .thenAnswer((_) async => list);
      when(() => itemRepository.getItemsForList(listId))
          .thenAnswer((_) async => items);
      when(() => itemRepository.deleteItem(any())).thenAnswer((_) async {});
      when(() => listRepository.deleteList(listId)).thenAnswer((_) async {});

      await useCase(listId);

      verify(() => itemRepository.deleteItem('item-1')).called(1);
      verify(() => itemRepository.deleteItem('item-2')).called(1);
    });

    test('does nothing when list is not found', () async {
      const listId = 'nonexistent';

      when(() => listRepository.getListById(listId))
          .thenAnswer((_) async => null);

      await useCase(listId);

      verifyNever(() => listRepository.deleteList(any()));
      verifyNever(() => itemRepository.deleteItem(any()));
      verifyNever(() => geofenceService.unregisterRegion(any()));
      verifyNever(() => geofenceRepository.deleteGeofence(any()));
    });
  });
}
