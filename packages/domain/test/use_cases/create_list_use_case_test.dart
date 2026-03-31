import 'package:domain/domain.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  late MockTodoListRepository repository;
  late CreateListUseCase useCase;

  setUp(() {
    repository = MockTodoListRepository();
    useCase = CreateListUseCase(repository);

    registerFallbackValue(
      TodoList(
        id: 'fallback',
        title: 'fallback',
        sortOrder: 0,
        createdAt: DateTime(2024),
      ),
    );
  });

  group('CreateListUseCase', () {
    test('creates list with sortOrder = max + 1 when lists exist', () async {
      when(() => repository.getAllLists()).thenAnswer(
        (_) async => [
          TodoList(
            id: 'a',
            title: 'A',
            sortOrder: 2,
            createdAt: DateTime(2024),
          ),
          TodoList(
            id: 'b',
            title: 'B',
            sortOrder: 5,
            createdAt: DateTime(2024),
          ),
        ],
      );
      when(() => repository.saveList(any())).thenAnswer((_) async {});

      final result = await useCase(title: 'New List');

      expect(result.sortOrder, equals(6));
      expect(result.title, equals('New List'));
    });

    test('creates list with sortOrder = 0 when no lists exist', () async {
      when(() => repository.getAllLists()).thenAnswer((_) async => []);
      when(() => repository.saveList(any())).thenAnswer((_) async {});

      final result = await useCase(title: 'First List');

      expect(result.sortOrder, equals(0));
    });

    test('generated UUID is non-empty', () async {
      when(() => repository.getAllLists()).thenAnswer((_) async => []);
      when(() => repository.saveList(any())).thenAnswer((_) async {});

      final result = await useCase(title: 'List');

      expect(result.id, isNotEmpty);
    });

    test('uses default color when none provided', () async {
      when(() => repository.getAllLists()).thenAnswer((_) async => []);
      when(() => repository.saveList(any())).thenAnswer((_) async {});

      final result = await useCase(title: 'Colored List');

      expect(result.color, equals(0xFF2196F3));
    });

    test('uses provided color', () async {
      when(() => repository.getAllLists()).thenAnswer((_) async => []);
      when(() => repository.saveList(any())).thenAnswer((_) async {});

      const customColor = 0xFFFF5722;
      final result = await useCase(title: 'Custom', color: customColor);

      expect(result.color, equals(customColor));
    });

    test('calls saveList with the created list', () async {
      when(() => repository.getAllLists()).thenAnswer((_) async => []);
      when(() => repository.saveList(any())).thenAnswer((_) async {});

      final result = await useCase(title: 'Saved');

      final captured =
          verify(() => repository.saveList(captureAny())).captured;
      expect(captured.single, equals(result));
    });
  });
}
