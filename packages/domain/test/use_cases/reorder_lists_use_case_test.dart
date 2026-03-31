import 'package:domain/domain.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  late MockTodoListRepository repository;
  late ReorderListsUseCase useCase;

  final createdAt = DateTime(2024);

  setUp(() {
    repository = MockTodoListRepository();
    useCase = ReorderListsUseCase(repository);

    registerFallbackValue(
      TodoList(
        id: 'fallback',
        title: 'fallback',
        sortOrder: 0,
        createdAt: createdAt,
      ),
    );
  });

  group('ReorderListsUseCase', () {
    test('saves each list with sortOrder matching its index in orderedIds',
        () async {
      final listA = TodoList(
        id: 'a',
        title: 'List A',
        sortOrder: 2,
        createdAt: createdAt,
      );
      final listB = TodoList(
        id: 'b',
        title: 'List B',
        sortOrder: 0,
        createdAt: createdAt,
      );
      final listC = TodoList(
        id: 'c',
        title: 'List C',
        sortOrder: 1,
        createdAt: createdAt,
      );

      when(() => repository.getListById('a')).thenAnswer((_) async => listA);
      when(() => repository.getListById('b')).thenAnswer((_) async => listB);
      when(() => repository.getListById('c')).thenAnswer((_) async => listC);
      when(() => repository.saveList(any())).thenAnswer((_) async {});

      await useCase(['b', 'c', 'a']);

      final captured =
          verify(() => repository.saveList(captureAny())).captured;

      expect(captured, hasLength(3));

      final savedById = {
        for (final l in captured.cast<TodoList>()) l.id: l,
      };

      expect(savedById['b']!.sortOrder, equals(0));
      expect(savedById['c']!.sortOrder, equals(1));
      expect(savedById['a']!.sortOrder, equals(2));
    });

    test('calls saveList for every id provided', () async {
      final lists = List.generate(
        5,
        (i) => TodoList(
          id: 'list-$i',
          title: 'List $i',
          sortOrder: i,
          createdAt: createdAt,
        ),
      );

      for (final l in lists) {
        when(() => repository.getListById(l.id)).thenAnswer((_) async => l);
      }
      when(() => repository.saveList(any())).thenAnswer((_) async {});

      final orderedIds = lists.reversed.map((l) => l.id).toList();
      await useCase(orderedIds);

      verify(() => repository.saveList(any())).called(5);
    });

    test('assigns sortOrder 0 to the first id in the list', () async {
      final list = TodoList(
        id: 'x',
        title: 'X',
        sortOrder: 99,
        createdAt: createdAt,
      );

      when(() => repository.getListById('x')).thenAnswer((_) async => list);
      when(() => repository.saveList(any())).thenAnswer((_) async {});

      await useCase(['x']);

      final captured =
          verify(() => repository.saveList(captureAny())).captured.single
              as TodoList;
      expect(captured.sortOrder, equals(0));
    });

    test('skips ids that are not found in the repository', () async {
      final list = TodoList(
        id: 'exists',
        title: 'Exists',
        sortOrder: 0,
        createdAt: createdAt,
      );

      when(() => repository.getListById('exists'))
          .thenAnswer((_) async => list);
      when(() => repository.getListById('missing'))
          .thenAnswer((_) async => null);
      when(() => repository.saveList(any())).thenAnswer((_) async {});

      // Should not throw; missing id is silently skipped.
      await useCase(['missing', 'exists']);

      final captured =
          verify(() => repository.saveList(captureAny())).captured;
      expect(captured, hasLength(1));
      expect((captured.single as TodoList).id, equals('exists'));
    });

    test('does nothing when orderedIds is empty', () async {
      await useCase([]);

      verifyNever(() => repository.getListById(any()));
      verifyNever(() => repository.saveList(any()));
    });

    test('preserves all other fields when updating sortOrder', () async {
      final list = TodoList(
        id: 'preserve',
        title: 'Preserve Me',
        color: 0xFFFF5722,
        notifyOnEnter: false,
        notifyOnExit: true,
        geofenceId: 'geo-abc',
        sortOrder: 7,
        createdAt: createdAt,
      );

      when(() => repository.getListById('preserve'))
          .thenAnswer((_) async => list);
      when(() => repository.saveList(any())).thenAnswer((_) async {});

      await useCase(['preserve']);

      final saved =
          verify(() => repository.saveList(captureAny())).captured.single
              as TodoList;

      expect(saved.id, equals('preserve'));
      expect(saved.title, equals('Preserve Me'));
      expect(saved.color, equals(0xFFFF5722));
      expect(saved.notifyOnEnter, isFalse);
      expect(saved.notifyOnExit, isTrue);
      expect(saved.geofenceId, equals('geo-abc'));
      expect(saved.createdAt, equals(createdAt));
      expect(saved.sortOrder, equals(0)); // updated to index 0
    });
  });
}
