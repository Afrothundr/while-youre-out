import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AppDatabase _memDb() => AppDatabase.forTesting(NativeDatabase.memory());

TodoList _makeList({
  String id = 'list-1',
  String title = 'Test List',
  int sortOrder = 0,
  String? geofenceId,
}) =>
    TodoList(
      id: id,
      title: title,
      sortOrder: sortOrder,
      createdAt: DateTime(2024),
      geofenceId: geofenceId,
    );

TodoItem _makeItem({
  String id = 'item-1',
  String listId = 'list-1',
  String title = 'Test Item',
  bool isDone = false,
  int priority = 0,
}) =>
    TodoItem(
      id: id,
      listId: listId,
      title: title,
      isDone: isDone,
      priority: priority,
      createdAt: DateTime(2024),
    );

GeofenceRegion _makeRegion({
  String id = 'geo-1',
  bool isActive = true,
  double latitude = 51.5,
  double longitude = -0.1,
}) =>
    GeofenceRegion(
      id: id,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: 200,
      createdAt: DateTime(2024),
      isActive: isActive,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DriftTodoListRepository', () {
    late AppDatabase db;
    late DriftTodoListRepository repo;

    setUp(() {
      db = _memDb();
      repo = DriftTodoListRepository(db);
    });

    tearDown(() => db.close());

    test('saveList + getAllLists roundtrip — saved list is returned', () async {
      final list = _makeList();
      await repo.saveList(list);

      final all = await repo.getAllLists();

      expect(all.length, 1);
      expect(all.first, list);
    });

    test('getAllLists returns lists ordered by sortOrder ascending', () async {
      final listA = _makeList(id: 'a', title: 'A', sortOrder: 2);
      final listB = _makeList(id: 'b', title: 'B');
      final listC = _makeList(id: 'c', title: 'C', sortOrder: 1);
      await repo.saveList(listA);
      await repo.saveList(listB);
      await repo.saveList(listC);

      final all = await repo.getAllLists();

      expect(all.map((l) => l.id).toList(), ['b', 'c', 'a']);
    });

    test('getListById returns correct list', () async {
      final list = _makeList(id: 'target');
      await repo.saveList(list);
      await repo.saveList(_makeList(id: 'other'));

      final found = await repo.getListById('target');

      expect(found, list);
    });

    test('getListById returns null when not found', () async {
      final result = await repo.getListById('does-not-exist');
      expect(result, isNull);
    });

    test('getListByGeofenceId returns correct list', () async {
      final list = _makeList(id: 'list-geo', geofenceId: 'geo-42');
      await repo.saveList(list);
      await repo.saveList(_makeList(id: 'no-geo'));

      final found = await repo.getListByGeofenceId('geo-42');

      expect(found, list);
    });

    test('getListByGeofenceId returns null when no match', () async {
      await repo.saveList(_makeList(geofenceId: 'geo-1'));

      final result = await repo.getListByGeofenceId('geo-999');

      expect(result, isNull);
    });

    test('saveList acts as upsert — updating an existing list', () async {
      final original = _makeList(title: 'Original');
      await repo.saveList(original);

      final updated = original.copyWith(title: 'Updated');
      await repo.saveList(updated);

      final all = await repo.getAllLists();
      expect(all.length, 1);
      expect(all.first.title, 'Updated');
    });

    test('deleteList removes the list', () async {
      final list = _makeList();
      await repo.saveList(list);
      await repo.deleteList(list.id);

      final all = await repo.getAllLists();
      expect(all, isEmpty);
    });

    test('watchAllLists emits updated list within 500 ms after insert',
        () async {
      final list = _makeList();

      // Subscribe before inserting so we don't miss the emission.
      final streamFuture = repo
          .watchAllLists()
          .firstWhere((lists) => lists.isNotEmpty);

      await repo.saveList(list);

      final lists =
          await streamFuture.timeout(const Duration(milliseconds: 500));
      expect(lists.length, 1);
      expect(lists.first, list);
    });
  });

  // -------------------------------------------------------------------------

  group('DriftTodoItemRepository', () {
    late AppDatabase db;
    late DriftTodoListRepository listRepo;
    late DriftTodoItemRepository itemRepo;

    setUp(() async {
      db = _memDb();
      listRepo = DriftTodoListRepository(db);
      itemRepo = DriftTodoItemRepository(db);
      // Most item tests require a parent list to satisfy the FK constraint.
      await listRepo.saveList(_makeList());
    });

    tearDown(() => db.close());

    test('saveItem + getItemsForList roundtrip', () async {
      final item = _makeItem();
      await itemRepo.saveItem(item);

      final items = await itemRepo.getItemsForList('list-1');

      expect(items.length, 1);
      expect(items.first, item);
    });

    test('getItemsForList orders by priority desc then isDone asc', () async {
      final high = _makeItem(id: 'h', priority: 3);
      final low = _makeItem(id: 'l');
      final mid = _makeItem(id: 'm', priority: 1);
      await itemRepo.saveItem(low);
      await itemRepo.saveItem(mid);
      await itemRepo.saveItem(high);

      final items = await itemRepo.getItemsForList('list-1');

      expect(items.map((i) => i.id).toList(), ['h', 'm', 'l']);
    });

    test('getItemById returns correct item', () async {
      final item = _makeItem(id: 'target-item');
      await itemRepo.saveItem(item);

      final found = await itemRepo.getItemById('target-item');

      expect(found, item);
    });

    test('getItemById returns null when not found', () async {
      final result = await itemRepo.getItemById('ghost');
      expect(result, isNull);
    });

    test('saveItem acts as upsert — updating an existing item', () async {
      final original = _makeItem(title: 'Original');
      await itemRepo.saveItem(original);

      final updated = original.copyWith(title: 'Updated', isDone: true);
      await itemRepo.saveItem(updated);

      final items = await itemRepo.getItemsForList('list-1');
      expect(items.length, 1);
      expect(items.first.title, 'Updated');
      expect(items.first.isDone, isTrue);
    });

    test('deleteItem removes the item', () async {
      final item = _makeItem();
      await itemRepo.saveItem(item);
      await itemRepo.deleteItem(item.id);

      final items = await itemRepo.getItemsForList('list-1');
      expect(items, isEmpty);
    });

    test('countIncompleteItems returns correct undone count', () async {
      await itemRepo.saveItem(_makeItem(id: 'i1'));
      await itemRepo.saveItem(_makeItem(id: 'i2'));
      await itemRepo.saveItem(_makeItem(id: 'i3', isDone: true));

      final count = await itemRepo.countIncompleteItems('list-1');

      expect(count, 2);
    });

    test('countIncompleteItems returns 0 when all items are done', () async {
      await itemRepo.saveItem(_makeItem(id: 'i1', isDone: true));
      await itemRepo.saveItem(_makeItem(id: 'i2', isDone: true));

      final count = await itemRepo.countIncompleteItems('list-1');

      expect(count, 0);
    });

    test('countIncompleteItems returns 0 for empty list', () async {
      final count = await itemRepo.countIncompleteItems('list-1');
      expect(count, 0);
    });

    test('deleteList cascades to todo_items', () async {
      await itemRepo.saveItem(_makeItem(id: 'i1'));
      await itemRepo.saveItem(_makeItem(id: 'i2'));

      await listRepo.deleteList('list-1');

      final items = await itemRepo.getItemsForList('list-1');
      expect(items, isEmpty);
    });
  });

  // -------------------------------------------------------------------------

  group('DriftGeofenceRepository', () {
    late AppDatabase db;
    late DriftGeofenceRepository repo;

    setUp(() {
      db = _memDb();
      repo = DriftGeofenceRepository(db);
    });

    tearDown(() => db.close());

    test('saveGeofence + getGeofenceById roundtrip', () async {
      final region = _makeRegion();
      await repo.saveGeofence(region);

      final found = await repo.getGeofenceById('geo-1');

      expect(found, region);
    });

    test('getGeofenceById returns null when not found', () async {
      final result = await repo.getGeofenceById('no-such-geo');
      expect(result, isNull);
    });

    test('getAllActiveGeofences returns only active regions', () async {
      final active = _makeRegion(id: 'active');
      final inactive = _makeRegion(id: 'inactive', isActive: false);
      await repo.saveGeofence(active);
      await repo.saveGeofence(inactive);

      final all = await repo.getAllActiveGeofences();

      expect(all.length, 1);
      expect(all.first.id, 'active');
    });

    test('saveGeofence acts as upsert — updating an existing region', () async {
      final original = _makeRegion();
      await repo.saveGeofence(original);

      final updated = original.copyWith(label: 'New Label');
      await repo.saveGeofence(updated);

      final found = await repo.getGeofenceById('geo-1');
      expect(found?.label, 'New Label');
    });

    test('deleteGeofence removes the region', () async {
      await repo.saveGeofence(_makeRegion());
      await repo.deleteGeofence('geo-1');

      final found = await repo.getGeofenceById('geo-1');
      expect(found, isNull);
    });

    test('setGeofenceActive(false) excludes region from getAllActiveGeofences',
        () async {
      await repo.saveGeofence(_makeRegion());

      await repo.setGeofenceActive('geo-1', active: false);

      final active = await repo.getAllActiveGeofences();
      expect(active, isEmpty);
    });

    test('setGeofenceActive(true) includes region in getAllActiveGeofences',
        () async {
      await repo.saveGeofence(_makeRegion(isActive: false));

      await repo.setGeofenceActive('geo-1', active: true);

      final active = await repo.getAllActiveGeofences();
      expect(active.length, 1);
      expect(active.first.id, 'geo-1');
    });

    test('GeofenceTrigger is round-tripped correctly for all values', () async {
      final enter = _makeRegion(id: 'enter').copyWith(
        trigger: GeofenceTrigger.enter,
      );
      final exit = _makeRegion(id: 'exit').copyWith(
        trigger: GeofenceTrigger.exit,
      );
      final both = _makeRegion(id: 'both').copyWith(
        trigger: GeofenceTrigger.enterAndExit,
      );

      await repo.saveGeofence(enter);
      await repo.saveGeofence(exit);
      await repo.saveGeofence(both);

      expect(
        (await repo.getGeofenceById('enter'))?.trigger,
        GeofenceTrigger.enter,
      );
      expect(
        (await repo.getGeofenceById('exit'))?.trigger,
        GeofenceTrigger.exit,
      );
      expect(
        (await repo.getGeofenceById('both'))?.trigger,
        GeofenceTrigger.enterAndExit,
      );
    });
  });
}
