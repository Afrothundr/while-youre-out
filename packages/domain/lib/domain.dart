/// Pure-Dart domain layer — entities, use cases, repository interfaces.
library domain;

// Entities
export 'src/entities/geofence_region.dart';
export 'src/entities/todo_item.dart';
export 'src/entities/todo_list.dart';

// Repository interfaces
export 'src/repositories/geofence_repository.dart';
export 'src/repositories/todo_item_repository.dart';
export 'src/repositories/todo_list_repository.dart';

// Service interfaces
export 'src/services/geofence_service.dart';
export 'src/services/notification_service.dart';

// Use cases
export 'src/use_cases/assign_location_use_case.dart';
export 'src/use_cases/create_item_use_case.dart';
export 'src/use_cases/create_list_use_case.dart';
export 'src/use_cases/delete_item_use_case.dart';
export 'src/use_cases/delete_list_use_case.dart';
export 'src/use_cases/handle_geofence_entry_use_case.dart';
export 'src/use_cases/refresh_active_geofences_use_case.dart';
export 'src/use_cases/register_geofence_use_case.dart';
export 'src/use_cases/reorder_lists_use_case.dart';
export 'src/use_cases/toggle_item_use_case.dart';
export 'src/use_cases/unregister_geofence_use_case.dart';
