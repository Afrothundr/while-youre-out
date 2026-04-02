// ignore_for_file: avoid_redundant_argument_values, cascade_invocations

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notifications/notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Register fallback values for types used with any() matchers.
    registerFallbackValue(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    registerFallbackValue(const NotificationDetails());
  });

  group('FlutterNotificationService', () {
    late _MockFlutterLocalNotificationsPlugin mockPlugin;
    late FlutterNotificationService service;

    setUp(() {
      mockPlugin = _MockFlutterLocalNotificationsPlugin();
      service = FlutterNotificationService(plugin: mockPlugin);

      // Default: quiet hours disabled so existing tests are unaffected.
      SharedPreferences.setMockInitialValues({
        'quiet_hours_enabled': false,
      });

      // Stub initialize to succeed.
      when(
        () => mockPlugin.initialize(
          any(),
          onDidReceiveNotificationResponse:
              any(named: 'onDidReceiveNotificationResponse'),
        ),
      ).thenAnswer((_) async => true);

      // Stub getNotificationAppLaunchDetails — no cold-start payload.
      when(() => mockPlugin.getNotificationAppLaunchDetails())
          .thenAnswer((_) async => null);

      // Stub platform-specific implementations to return null so the
      // Android-channel creation and iOS permission-request paths are no-ops.
      when(
        () => mockPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>(),
      ).thenReturn(null);
      when(
        () => mockPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>(),
      ).thenReturn(null);

      // Stub show to succeed silently.
      when(
        () => mockPlugin.show(
          any(),
          any(),
          any(),
          any(),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});
    });

    // -------------------------------------------------------------------------
    // postListNotification
    // -------------------------------------------------------------------------

    group('postListNotification', () {
      test('calls show with correct id, title, plural body, and payload',
          () async {
        await service.postListNotification(
          listId: 'list-1',
          listTitle: 'Groceries',
          incompleteCount: 3,
        );

        verify(
          () => mockPlugin.show(
            'list-1'.hashCode,
            'Groceries',
            '3 items remaining',
            any(),
            payload: 'list-1',
          ),
        ).called(1);
      });

      test('uses singular body when incompleteCount is 1', () async {
        await service.postListNotification(
          listId: 'list-2',
          listTitle: 'Hardware Store',
          incompleteCount: 1,
        );

        verify(
          () => mockPlugin.show(
            'list-2'.hashCode,
            'Hardware Store',
            '1 item remaining',
            any(),
            payload: 'list-2',
          ),
        ).called(1);
      });

      test('derives a stable notification ID from listId.hashCode', () async {
        const listId = 'stable-list-id';

        await service.postListNotification(
          listId: listId,
          listTitle: 'Test List',
          incompleteCount: 2,
        );

        verify(
          () => mockPlugin.show(
            listId.hashCode,
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          ),
        ).called(1);
      });
    });

    // -------------------------------------------------------------------------
    // initialize
    // -------------------------------------------------------------------------

    group('initialize', () {
      test('calls plugin initialize once', () async {
        await service.initialize();

        verify(
          () => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse'),
          ),
        ).called(1);
      });

      test(
          'queries getNotificationAppLaunchDetails '
          'for cold-start handling', () async {
        await service.initialize();

        verify(() => mockPlugin.getNotificationAppLaunchDetails()).called(1);
      });

      test('does not invoke tap callback when no cold-start payload', () async {
        var callbackInvoked = false;
        service.notificationTapCallback = (_) => callbackInvoked = true;

        when(() => mockPlugin.getNotificationAppLaunchDetails())
            .thenAnswer((_) async => null);

        await service.initialize();

        expect(callbackInvoked, isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // notificationTapCallback setter
    // -------------------------------------------------------------------------

    group('notificationTapCallback', () {
      test('invokes registered callback with listId when notification tapped',
          () async {
        await service.initialize();

        // Capture the onDidReceiveNotificationResponse passed to initialize.
        final captured = verify(
          () => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse: captureAny(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).captured;

        final onTapped =
            captured.first as void Function(NotificationResponse);

        String? receivedListId;
        service.notificationTapCallback = (listId) => receivedListId = listId;

        onTapped(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: 'list-abc',
          ),
        );

        expect(receivedListId, equals('list-abc'));
      });

      test('does not invoke callback when notification payload is null',
          () async {
        await service.initialize();

        final captured = verify(
          () => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse: captureAny(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).captured;

        final onTapped =
            captured.first as void Function(NotificationResponse);

        var callbackInvoked = false;
        service.notificationTapCallback = (_) => callbackInvoked = true;

        onTapped(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
          ),
        );

        expect(callbackInvoked, isFalse);
      });

      test('replaces previously registered callback', () async {
        await service.initialize();

        final captured = verify(
          () => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse: captureAny(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).captured;

        final onTapped =
            captured.first as void Function(NotificationResponse);

        var firstCallbackCount = 0;
        var secondCallbackCount = 0;

        service.notificationTapCallback = (_) => firstCallbackCount++;
        service.notificationTapCallback = (_) => secondCallbackCount++;

        onTapped(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: 'list-xyz',
          ),
        );

        expect(firstCallbackCount, equals(0));
        expect(secondCallbackCount, equals(1));
      });
    });

    // -------------------------------------------------------------------------
    // requestPermission
    // -------------------------------------------------------------------------

    group('requestPermission', () {
      test('returns true when iOS implementation is not available', () async {
        when(
          () => mockPlugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>(),
        ).thenReturn(null);

        final result = await service.requestPermission();

        expect(result, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // Quiet hours — postListNotification suppression
    // -------------------------------------------------------------------------

    group('quiet hours', () {
      /// Creates a [FlutterNotificationService] with a fixed [now] time
      /// injected so tests are deterministic regardless of wall-clock time.
      FlutterNotificationService serviceAt(TimeOfDay now) {
        return FlutterNotificationService(
          plugin: mockPlugin,
          nowProvider: () => now,
        );
      }

      tearDown(() async {
        // Reset SharedPreferences between tests.
        SharedPreferences.setMockInitialValues({});
      });

      test('suppresses show when current time is inside quiet window',
          () async {
        // Quiet window: 22:00–07:00 (overnight). Current time: 23:00.
        SharedPreferences.setMockInitialValues({
          'quiet_hours_enabled': true,
          'quiet_hours_start': 1320, // 22:00
          'quiet_hours_end': 420, // 07:00
        });

        final svc = serviceAt(const TimeOfDay(hour: 23, minute: 0));

        await svc.postListNotification(
          listId: 'list-1',
          listTitle: 'Groceries',
          incompleteCount: 2,
        );

        verifyNever(
          () => mockPlugin.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          ),
        );
      });

      test('suppresses show for overnight range when time is before end',
          () async {
        // Quiet window: 22:00–07:00. Current time: 03:00 (early morning).
        SharedPreferences.setMockInitialValues({
          'quiet_hours_enabled': true,
          'quiet_hours_start': 1320, // 22:00
          'quiet_hours_end': 420, // 07:00
        });

        final svc = serviceAt(const TimeOfDay(hour: 3, minute: 0));

        await svc.postListNotification(
          listId: 'list-2',
          listTitle: 'Hardware Store',
          incompleteCount: 1,
        );

        verifyNever(
          () => mockPlugin.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          ),
        );
      });

      test('calls show when current time is outside the quiet window',
          () async {
        // Quiet window: 22:00–07:00. Current time: 10:00 (daytime).
        SharedPreferences.setMockInitialValues({
          'quiet_hours_enabled': true,
          'quiet_hours_start': 1320, // 22:00
          'quiet_hours_end': 420, // 07:00
        });

        final svc = serviceAt(const TimeOfDay(hour: 10, minute: 0));

        await svc.postListNotification(
          listId: 'list-3',
          listTitle: 'Pharmacy',
          incompleteCount: 3,
        );

        verify(
          () => mockPlugin.show(
            'list-3'.hashCode,
            'Pharmacy',
            '3 items remaining',
            any(),
            payload: 'list-3',
          ),
        ).called(1);
      });

      test('calls show when quiet hours are disabled', () async {
        SharedPreferences.setMockInitialValues({
          'quiet_hours_enabled': false,
        });

        final svc = serviceAt(const TimeOfDay(hour: 23, minute: 30));

        await svc.postListNotification(
          listId: 'list-4',
          listTitle: 'Night List',
          incompleteCount: 1,
        );

        verify(
          () => mockPlugin.show(
            'list-4'.hashCode,
            'Night List',
            '1 item remaining',
            any(),
            payload: 'list-4',
          ),
        ).called(1);
      });

      test('suppresses show for same-day quiet window when time is inside',
          () async {
        // Same-day window: 13:00–14:00. Current time: 13:30.
        SharedPreferences.setMockInitialValues({
          'quiet_hours_enabled': true,
          'quiet_hours_start': 780, // 13:00
          'quiet_hours_end': 840, // 14:00
        });

        final svc = serviceAt(const TimeOfDay(hour: 13, minute: 30));

        await svc.postListNotification(
          listId: 'list-5',
          listTitle: 'Lunch List',
          incompleteCount: 2,
        );

        verifyNever(
          () => mockPlugin.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          ),
        );
      });
    });
  });
}
