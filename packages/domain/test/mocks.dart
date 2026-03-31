import 'package:domain/domain.dart';
import 'package:mocktail/mocktail.dart';

class MockTodoListRepository extends Mock implements TodoListRepository {}

class MockTodoItemRepository extends Mock implements TodoItemRepository {}

class MockGeofenceRepository extends Mock implements GeofenceRepository {}

class MockGeofenceService extends Mock implements GeofenceService {}

class MockNotificationService extends Mock implements NotificationService {}
