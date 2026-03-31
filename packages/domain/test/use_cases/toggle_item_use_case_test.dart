import 'package:domain/domain.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  late MockTodoItemRepository repository;
  late ToggleItemUseCase useCase;

  final createdAt = DateTime(2024);

  setUp(() {
    repository = MockTodoItemRepository();
    useCase = ToggleItemUseCase(repository);

    registerFallbackValue(
      TodoItem(
        id: 'fallback',
        listId: 'fallback-list',
        title: 'fallback',
        createdAt: createdAt,
      ),
    );
  });

  group('ToggleItemUseCase', () {
    test('flips isDone from false to true', () async {
      const itemId = 'item-1';
      final item = TodoItem(
        id: itemId,
        listId: 'list-1',
        title: 'Buy milk',

        createdAt: createdAt,
      );

      when(() => repository.getItemById(itemId)).thenAnswer((_) async => item);
      when(() => repository.saveItem(any())).thenAnswer((_) async {});

      final result = await useCase(itemId);

      expect(result, isNotNull);
      expect(result!.isDone, isTrue);
      expect(result.id, equals(itemId));

      final captured =
          verify(() => repository.saveItem(captureAny())).captured.single
              as TodoItem;
      expect(captured.isDone, isTrue);
    });

    test('flips isDone from true to false', () async {
      const itemId = 'item-2';
      final item = TodoItem(
        id: itemId,
        listId: 'list-1',
        title: 'Walk the dog',
        isDone: true,
        createdAt: createdAt,
      );

      when(() => repository.getItemById(itemId)).thenAnswer((_) async => item);
      when(() => repository.saveItem(any())).thenAnswer((_) async {});

      final result = await useCase(itemId);

      expect(result, isNotNull);
      expect(result!.isDone, isFalse);

      final captured =
          verify(() => repository.saveItem(captureAny())).captured.single
              as TodoItem;
      expect(captured.isDone, isFalse);
    });

    test('returns null when item is not found', () async {
      when(() => repository.getItemById(any())).thenAnswer((_) async => null);

      final result = await useCase('nonexistent');

      expect(result, isNull);
      verifyNever(() => repository.saveItem(any()));
    });

    test('preserves all other fields when toggling', () async {
      const itemId = 'item-3';
      final dueDate = DateTime(2025, 6, 15);
      final item = TodoItem(
        id: itemId,
        listId: 'list-42',
        title: 'Original Title',
        notes: 'Some notes',

        dueDate: dueDate,
        priority: 2,
        createdAt: createdAt,
      );

      when(() => repository.getItemById(itemId)).thenAnswer((_) async => item);
      when(() => repository.saveItem(any())).thenAnswer((_) async {});

      final result = await useCase(itemId);

      expect(result, isNotNull);
      expect(result!.isDone, isTrue);
      expect(result.listId, equals('list-42'));
      expect(result.title, equals('Original Title'));
      expect(result.notes, equals('Some notes'));
      expect(result.dueDate, equals(dueDate));
      expect(result.priority, equals(2));
      expect(result.createdAt, equals(createdAt));
    });
  });
}
