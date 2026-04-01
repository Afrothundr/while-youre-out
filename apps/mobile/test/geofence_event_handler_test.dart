import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whileyoureout/geofence_event_handler.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockGeofenceService extends Mock implements GeofenceService {}

class _MockHandleGeofenceEntryUseCase extends Mock
    implements HandleGeofenceEntryUseCase {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns a [GeofenceEvent] with the given [type] and an optional [regionId].
GeofenceEvent _makeEvent({
  GeofenceEventType type = GeofenceEventType.enter,
  String regionId = 'region-1',
}) {
  return GeofenceEvent(
    regionId: regionId,
    type: type,
    timestamp: DateTime(2024),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late StreamController<GeofenceEvent> eventController;
  late _MockGeofenceService mockGeofenceService;
  late _MockHandleGeofenceEntryUseCase mockHandleEntry;
  late GeofenceEventHandler handler;

  setUp(() {
    eventController = StreamController<GeofenceEvent>.broadcast();
    mockGeofenceService = _MockGeofenceService();
    mockHandleEntry = _MockHandleGeofenceEntryUseCase();

    when(() => mockGeofenceService.events)
        .thenAnswer((_) => eventController.stream);

    // Default stub: use case succeeds silently.
    when(() => mockHandleEntry.call(any())).thenAnswer((_) async {});

    handler = GeofenceEventHandler(
      geofenceService: mockGeofenceService,
      handleEntry: mockHandleEntry,
    );
  });

  tearDown(() async {
    handler.dispose();
    await eventController.close();
  });

  group('GeofenceEventHandler', () {
    // -------------------------------------------------------------------------
    // start / enter events
    // -------------------------------------------------------------------------

    group('start', () {
      test('calls HandleGeofenceEntryUseCase with regionId on enter event',
          () async {
        handler.start();

        eventController.add(_makeEvent(regionId: 'region-abc'));

        // Yield so the async stream listener has a chance to run.
        await Future<void>.delayed(Duration.zero);

        verify(() => mockHandleEntry.call('region-abc')).called(1);
      });

      test('handles multiple enter events in sequence', () async {
        handler.start();

        eventController
          ..add(_makeEvent())
          ..add(_makeEvent(regionId: 'region-2'))
          ..add(_makeEvent(regionId: 'region-3'));

        await Future<void>.delayed(Duration.zero);

        verify(() => mockHandleEntry.call('region-1')).called(1);
        verify(() => mockHandleEntry.call('region-2')).called(1);
        verify(() => mockHandleEntry.call('region-3')).called(1);
      });

      test('does NOT call HandleGeofenceEntryUseCase on exit event', () async {
        handler.start();

        eventController.add(_makeEvent(type: GeofenceEventType.exit));

        await Future<void>.delayed(Duration.zero);

        verifyNever(() => mockHandleEntry.call(any()));
      });

      test(
          'ignores exit events while still processing enter events',
          () async {
        handler.start();

        eventController
          ..add(_makeEvent(
            type: GeofenceEventType.exit,
            regionId: 'region-exit',
          ),)
          ..add(_makeEvent(regionId: 'region-enter'))
          ..add(_makeEvent(
            type: GeofenceEventType.exit,
            regionId: 'region-exit-2',
          ),);

        await Future<void>.delayed(Duration.zero);

        verify(() => mockHandleEntry.call('region-enter')).called(1);
        verifyNever(() => mockHandleEntry.call('region-exit'));
        verifyNever(() => mockHandleEntry.call('region-exit-2'));
      });

      test(
          'is idempotent — calling start twice subscribes only once',
          () async {
        // Second call should be a no-op.
        handler
          ..start()
          ..start();

        eventController.add(_makeEvent());

        await Future<void>.delayed(Duration.zero);

        // Use case is called once even though start was called twice.
        verify(() => mockHandleEntry.call('region-1')).called(1);
      });
    });

    // -------------------------------------------------------------------------
    // dispose
    // -------------------------------------------------------------------------

    group('dispose', () {
      test('cancels subscription — events after dispose are not processed',
          () async {
        handler.start();

        // Emit one event before dispose.
        eventController.add(_makeEvent(regionId: 'before-dispose'));
        await Future<void>.delayed(Duration.zero);

        handler.dispose();

        // Emit one event after dispose.
        eventController.add(_makeEvent(regionId: 'after-dispose'));
        await Future<void>.delayed(Duration.zero);

        verify(() => mockHandleEntry.call('before-dispose')).called(1);
        verifyNever(() => mockHandleEntry.call('after-dispose'));
      });

      test('is safe to call without calling start first', () {
        // Should not throw.
        expect(handler.dispose, returnsNormally);
      });

      test('is safe to call multiple times', () {
        handler
          ..start()
          ..dispose();

        // Should not throw on a second dispose call.
        expect(handler.dispose, returnsNormally);
      });

      test('allows restart after dispose by calling start again', () async {
        // start → dispose → re-subscribe.
        handler
          ..start()
          ..dispose()
          ..start();

        eventController.add(_makeEvent(regionId: 'region-restarted'));
        await Future<void>.delayed(Duration.zero);

        verify(() => mockHandleEntry.call('region-restarted')).called(1);
      });
    });
  });
}
