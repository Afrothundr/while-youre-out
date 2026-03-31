import 'package:domain/domain.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  late MockTodoListRepository listRepository;
  late MockTodoItemRepository itemRepository;
  late MockNotificationService notificationService;
  late HandleGeofenceEntryUseCase useCase;

  final createdAt = DateTime(2024);

  setUp(() {
    listRepository = MockTodoListRepository();
    itemRepository = MockTodoItemRepository();
    notificationService = MockNotificationService();

    useCase = HandleGeofenceEntryUseCase(
      listRepository,
      itemRepository,
      notificationService,
    );

    registerFallbackValue(
      TodoList(
        id: 'fallback',
        title: 'fallback',
        sortOrder: 0,
        createdAt: createdAt,
      ),
    );
  });

  group('HandleGeofenceEntryUseCase', () {
    test('posts notification with correct listTitle and incompleteCount',
        () async {
      const regionId = 'region-1';
      const listId = 'list-1';
      const listTitle = 'Grocery Run';
      const incompleteCount = 4;

      final list = TodoList(
        id: listId,
        title: listTitle,
        geofenceId: regionId,
        sortOrder: 0,
        createdAt: createdAt,
      );

      when(() => listRepository.getListByGeofenceId(regionId))
          .thenAnswer((_) async => list);
      when(() => itemRepository.countIncompleteItems(listId))
          .thenAnswer((_) async => incompleteCount);
      when(
        () => notificationService.postListNotification(
          listId: any(named: 'listId'),
          listTitle: any(named: 'listTitle'),
          incompleteCount: any(named: 'incompleteCount'),
        ),
      ).thenAnswer((_) async {});

      await useCase(regionId);

      verify(
        () => notificationService.postListNotification(
          listId: listId,
          listTitle: listTitle,
          incompleteCount: incompleteCount,
        ),
      ).called(1);
    });

    test('posts notification with incompleteCount = 0 when all items are done',
        () async {
      const regionId = 'region-2';
      const listId = 'list-2';

      final list = TodoList(
        id: listId,
        title: 'All Done',
        geofenceId: regionId,
        sortOrder: 0,
        createdAt: createdAt,
      );

      when(() => listRepository.getListByGeofenceId(regionId))
          .thenAnswer((_) async => list);
      when(() => itemRepository.countIncompleteItems(listId))
          .thenAnswer((_) async => 0);
      when(
        () => notificationService.postListNotification(
          listId: any(named: 'listId'),
          listTitle: any(named: 'listTitle'),
          incompleteCount: any(named: 'incompleteCount'),
        ),
      ).thenAnswer((_) async {});

      await useCase(regionId);

      verify(
        () => notificationService.postListNotification(
          listId: listId,
          listTitle: 'All Done',
          incompleteCount: 0,
        ),
      ).called(1);
    });

    test('returns early without posting notification when no list found',
        () async {
      const regionId = 'unknown-region';

      when(() => listRepository.getListByGeofenceId(regionId))
          .thenAnswer((_) async => null);

      await useCase(regionId);

      verifyNever(
        () => notificationService.postListNotification(
          listId: any(named: 'listId'),
          listTitle: any(named: 'listTitle'),
          incompleteCount: any(named: 'incompleteCount'),
        ),
      );
      verifyNever(() => itemRepository.countIncompleteItems(any()));
    });

    test('uses the list id (not regionId) when posting notification', () async {
      const regionId = 'region-3';
      const listId = 'list-99';

      final list = TodoList(
        id: listId,
        title: 'Hardware Store',
        geofenceId: regionId,
        sortOrder: 0,
        createdAt: createdAt,
      );

      when(() => listRepository.getListByGeofenceId(regionId))
          .thenAnswer((_) async => list);
      when(() => itemRepository.countIncompleteItems(listId))
          .thenAnswer((_) async => 7);
      when(
        () => notificationService.postListNotification(
          listId: any(named: 'listId'),
          listTitle: any(named: 'listTitle'),
          incompleteCount: any(named: 'incompleteCount'),
        ),
      ).thenAnswer((_) async {});

      await useCase(regionId);

      final captured = verify(
        () => notificationService.postListNotification(
          listId: captureAny(named: 'listId'),
          listTitle: captureAny(named: 'listTitle'),
          incompleteCount: captureAny(named: 'incompleteCount'),
        ),
      ).captured;

      // captured order matches named parameter declaration order
      expect(captured[0], equals(listId));
      expect(captured[1], equals('Hardware Store'));
      expect(captured[2], equals(7));
    });
  });
}
