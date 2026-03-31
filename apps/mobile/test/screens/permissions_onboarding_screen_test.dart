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
          requestPermission: requestPermission ??
              (_) async => PermissionStatus.denied,
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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PermissionsOnboardingScreen', () {
    testWidgets('shows step 1 content on first render', (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pumpAndSettle();

      expect(find.text('Show your location on the map'), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Step 2 content should NOT be visible yet.
      expect(find.text('Get notified when you arrive'), findsNothing);
    });

    testWidgets('step 2 is not visible before tapping Continue',
        (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pumpAndSettle();

      expect(find.text('Allow Background Location'), findsNothing);
      expect(find.text('Get notified when you arrive'), findsNothing);
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
      // Permission always returns denied so the page animates forward.
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

    testWidgets('completing step 2 sets onboarding_complete = true',
        (tester) async {
      final onCompleteCalled = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        _buildHarness(
          requestPermission: (_) async => PermissionStatus.denied,
          onCompleteCalled: onCompleteCalled,
        ),
      );
      await tester.pumpAndSettle();

      // --- Step 1: tap Continue ---
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Ensure we are on step 2.
      expect(find.text('Get notified when you arrive'), findsOneWidget);

      // Before tapping "Allow Background Location", we show "Not now".
      expect(find.text('Not now'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), isTrue);
    });

    testWidgets('onComplete callback is invoked after finishing step 2',
        (tester) async {
      final onCompleteCalled = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        _buildHarness(
          requestPermission: (_) async => PermissionStatus.denied,
          onCompleteCalled: onCompleteCalled,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(onCompleteCalled.value, isTrue);
    });
  });
}
