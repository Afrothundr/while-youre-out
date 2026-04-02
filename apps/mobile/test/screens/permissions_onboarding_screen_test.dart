import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whileyoureout/screens/onboarding/permissions_onboarding_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a [PermissionsOnboardingScreen] wrapped in a [GoRouter]-backed app.
///
/// [requestPermission] is injected so tests can control what the permission
/// dialogs return without hitting platform channels.
/// [onCompleteCalled] is set to true when the screen finishes onboarding.
Widget _buildHarness({
  RequestPermissionCallback? requestPermission,
  ValueNotifier<bool>? onCompleteCalled,
}) {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => PermissionsOnboardingScreen(
          requestPermission:
              requestPermission ?? (_) async => PermissionStatus.denied,
          onComplete: (context) {
            onCompleteCalled?.value = true;
          },
        ),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('Dashboard')),
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

/// Returns a [RequestPermissionCallback] that maps specific [Permission]s to
/// the supplied [PermissionStatus] values. Any unmapped permission returns
/// [PermissionStatus.denied].
RequestPermissionCallback _makePermissionCallback({
  PermissionStatus whenInUse = PermissionStatus.denied,
  PermissionStatus always = PermissionStatus.denied,
  PermissionStatus notification = PermissionStatus.denied,
}) {
  return (permission) async {
    if (permission == Permission.locationWhenInUse) return whenInUse;
    if (permission == Permission.locationAlways) return always;
    if (permission == Permission.notification) return notification;
    return PermissionStatus.denied;
  };
}

/// Drives step 1 (when-in-use) by tapping the Continue button and waiting for
/// the page animation to finish.
Future<void> _advanceThroughStep1(WidgetTester tester) async {
  await tester.tap(find.text('Continue'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

/// Drives step 2 (always-on) to step 3 by tapping "Allow Background Location"
/// with an injected *granted* result, which auto-advances to the notification
/// page.
///
/// Callers must ensure the [RequestPermissionCallback] returns
/// [PermissionStatus.granted] for [Permission.locationAlways].
Future<void> _advanceThroughStep2Granted(WidgetTester tester) async {
  await tester.tap(find.text('Allow Background Location'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PermissionsOnboardingScreen', () {
    // -----------------------------------------------------------------------
    // Step 1 — When In Use
    // -----------------------------------------------------------------------

    testWidgets('shows step 1 content on first render', (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pumpAndSettle();

      expect(find.text('Show your location on the map'), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Step 2 content should NOT be visible yet.
      expect(find.text('Get notified when you arrive'), findsNothing);
    });

    testWidgets('steps 2 and 3 are not visible before tapping Continue',
        (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pumpAndSettle();

      expect(find.text('Allow Background Location'), findsNothing);
      expect(find.text('Get notified when you arrive'), findsNothing);
      expect(find.text('Stay in the loop'), findsNothing);
    });

    testWidgets('step 1 does not show denial note before any interaction',
        (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pumpAndSettle();

      expect(
        find.text('You can set locations manually by tapping the map.'),
        findsNothing,
      );
    });

    testWidgets('tapping Continue on step 1 advances to step 2',
        (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          requestPermission: (_) async => PermissionStatus.denied,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      // Drive the 350 ms page animation.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Get notified when you arrive'), findsOneWidget);
    });

    testWidgets(
        'step 1 denial note is shown after when-in-use is denied',
        (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          requestPermission: (_) async => PermissionStatus.denied,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      // Pump a single frame so the setState from the permission result is
      // applied, before the page animation moves the content off-screen.
      await tester.pump();

      expect(
        find.text('You can set locations manually by tapping the map.'),
        findsOneWidget,
      );
    });

    // -----------------------------------------------------------------------
    // Step 2 — Always On
    // -----------------------------------------------------------------------

    testWidgets('"Not now" on step 2 advances to step 3 (not finish)',
        (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          requestPermission: _makePermissionCallback(),
        ),
      );
      await tester.pumpAndSettle();

      await _advanceThroughStep1(tester);
      expect(find.text('Get notified when you arrive'), findsOneWidget);

      await tester.tap(find.text('Not now'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Should be on step 3, not finished.
      expect(find.text('Stay in the loop'), findsOneWidget);
    });

    testWidgets(
        '"Allow Background Location" (granted) auto-advances to step 3',
        (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          requestPermission: _makePermissionCallback(
            always: PermissionStatus.granted,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _advanceThroughStep1(tester);
      await _advanceThroughStep2Granted(tester);

      expect(find.text('Stay in the loop'), findsOneWidget);
    });

    testWidgets(
        '"Allow Background Location" (denied) shows warning and Continue',
        (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          requestPermission: _makePermissionCallback(),
        ),
      );
      await tester.pumpAndSettle();

      await _advanceThroughStep1(tester);
      await tester.tap(find.text('Allow Background Location'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          "Arrival reminders won't work without background location",
        ),
        findsOneWidget,
      );
      // "Done" was the old label; it should now read "Continue" since the
      // next step is notifications, not the end of onboarding.
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('"Continue" after always-denied advances to step 3',
        (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          requestPermission: _makePermissionCallback(),
        ),
      );
      await tester.pumpAndSettle();

      await _advanceThroughStep1(tester);
      // Deny always permission to show the warning + Continue button.
      await tester.tap(find.text('Allow Background Location'));
      await tester.pumpAndSettle();

      // Tap Continue on the denied state to advance to step 3.
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Stay in the loop'), findsOneWidget);
    });

    testWidgets('"Not now" on step 2 does NOT set onboarding_complete',
        (tester) async {
      final onCompleteCalled = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        _buildHarness(
          requestPermission: _makePermissionCallback(),
          onCompleteCalled: onCompleteCalled,
        ),
      );
      await tester.pumpAndSettle();

      await _advanceThroughStep1(tester);
      await tester.tap(find.text('Not now'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Onboarding must NOT be complete yet — step 3 is still pending.
      expect(onCompleteCalled.value, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), isNull);
    });

    // -----------------------------------------------------------------------
    // Step 3 — Notifications
    // -----------------------------------------------------------------------

    testWidgets('step 3 shows notification permission content', (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          requestPermission: _makePermissionCallback(
            always: PermissionStatus.granted,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _advanceThroughStep1(tester);
      await _advanceThroughStep2Granted(tester);

      expect(find.text('Stay in the loop'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.text('Allow Notifications'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
      expect(
        find.textContaining("We'll notify you when you arrive"),
        findsOneWidget,
      );
    });

    testWidgets('step 3 does not show denial message before requesting',
        (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          requestPermission: _makePermissionCallback(
            always: PermissionStatus.granted,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _advanceThroughStep1(tester);
      await _advanceThroughStep2Granted(tester);

      expect(find.textContaining('Notifications are disabled'), findsNothing);
    });

    testWidgets('"Not now" on step 3 sets onboarding_complete = true',
        (tester) async {
      final onCompleteCalled = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        _buildHarness(
          requestPermission: _makePermissionCallback(
            always: PermissionStatus.granted,
          ),
          onCompleteCalled: onCompleteCalled,
        ),
      );
      await tester.pumpAndSettle();

      await _advanceThroughStep1(tester);
      await _advanceThroughStep2Granted(tester);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), isTrue);
    });

    testWidgets('onComplete callback is invoked after finishing step 3',
        (tester) async {
      final onCompleteCalled = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        _buildHarness(
          requestPermission: _makePermissionCallback(
            always: PermissionStatus.granted,
          ),
          onCompleteCalled: onCompleteCalled,
        ),
      );
      await tester.pumpAndSettle();

      await _advanceThroughStep1(tester);
      await _advanceThroughStep2Granted(tester);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(onCompleteCalled.value, isTrue);
    });

    testWidgets(
        '"Allow Notifications" (granted) finishes onboarding immediately',
        (tester) async {
      final onCompleteCalled = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        _buildHarness(
          requestPermission: _makePermissionCallback(
            always: PermissionStatus.granted,
            notification: PermissionStatus.granted,
          ),
          onCompleteCalled: onCompleteCalled,
        ),
      );
      await tester.pumpAndSettle();

      await _advanceThroughStep1(tester);
      await _advanceThroughStep2Granted(tester);

      await tester.tap(find.text('Allow Notifications'));
      await tester.pumpAndSettle();

      expect(onCompleteCalled.value, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), isTrue);
    });

    testWidgets(
        '"Allow Notifications" (denied) shows informational message',
        (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          requestPermission: _makePermissionCallback(
            always: PermissionStatus.granted,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _advanceThroughStep1(tester);
      await _advanceThroughStep2Granted(tester);

      await tester.tap(find.text('Allow Notifications'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Notifications are disabled. You can enable them later in '
          'your device Settings.',
        ),
        findsOneWidget,
      );
      // The "Done" button replaces "Allow Notifications" + "Not now".
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Allow Notifications'), findsNothing);
      expect(find.text('Not now'), findsNothing);
    });

    testWidgets('"Done" after notification denied finishes onboarding',
        (tester) async {
      final onCompleteCalled = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        _buildHarness(
          requestPermission: _makePermissionCallback(
            always: PermissionStatus.granted,
          ),
          onCompleteCalled: onCompleteCalled,
        ),
      );
      await tester.pumpAndSettle();

      await _advanceThroughStep1(tester);
      await _advanceThroughStep2Granted(tester);

      await tester.tap(find.text('Allow Notifications'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(onCompleteCalled.value, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), isTrue);
    });

    testWidgets(
        'full flow (all denied) sets onboarding_complete and calls onComplete',
        (tester) async {
      final onCompleteCalled = ValueNotifier<bool>(false);

      // Simulate a user who denies every permission but completes all steps.
      await tester.pumpWidget(
        _buildHarness(
          requestPermission: _makePermissionCallback(),
          onCompleteCalled: onCompleteCalled,
        ),
      );
      await tester.pumpAndSettle();

      // Step 1 → Step 2 (denied, advance via Continue).
      await _advanceThroughStep1(tester);

      // Step 2 → Step 3 via "Not now".
      await tester.tap(find.text('Not now'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Stay in the loop'), findsOneWidget);

      // Step 3 → Done via "Not now".
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(onCompleteCalled.value, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), isTrue);
    });
  });
}
