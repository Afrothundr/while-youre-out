import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whileyoureout/screens/dashboard/dashboard_screen.dart';
import 'package:whileyoureout/screens/list_detail/list_detail_screen.dart';
import 'package:whileyoureout/screens/map_picker/map_picker_screen.dart';
import 'package:whileyoureout/screens/onboarding/permissions_onboarding_screen.dart';

/// Route path constants.
abstract final class AppRoutes {
  /// Dashboard (home) route.
  static const String dashboard = '/';

  /// List detail route. Expects `:listId` path parameter.
  static const String listDetail = '/list/:listId';

  /// Map picker route. Expects `:listId` path parameter.
  static const String mapPicker = '/list/:listId/map';

  /// Permissions onboarding route.
  static const String onboarding = '/onboarding';

  /// Builds a concrete list detail path for navigation.
  static String listDetailPath(String listId) => '/list/$listId';

  /// Builds a concrete map picker path for navigation.
  static String mapPickerPath(String listId) => '/list/$listId/map';
}

/// Provides an initialised [SharedPreferences] instance, loaded once at
/// app startup. The router depends on this to decide whether to show
/// the onboarding screen.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

/// The application's [GoRouter] instance, exposed as a Riverpod provider so
/// that screens can read it without a [BuildContext].
final appRouterProvider = Provider<GoRouter>((ref) {
  // Watch shared preferences synchronously (may be null before resolved).
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  final prefs = prefsAsync.valueOrNull;

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    redirect: (context, state) {
      // If prefs haven't loaded yet, don't redirect.
      if (prefs == null) return null;

      final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
      if (!onboardingComplete &&
          state.matchedLocation != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.listDetail,
        builder: (context, state) {
          final listId = state.pathParameters['listId']!;
          return ListDetailScreen(listId: listId);
        },
        routes: [
          GoRoute(
            path: 'map',
            builder: (context, state) {
              final listId = state.pathParameters['listId']!;
              return MapPickerScreen(listId: listId);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const PermissionsOnboardingScreen(),
      ),
    ],
    // Fallback for unknown routes — send user back to dashboard.
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
