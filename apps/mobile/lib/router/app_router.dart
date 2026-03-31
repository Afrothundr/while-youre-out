import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whileyoureout/screens/dashboard/dashboard_screen.dart';
import 'package:whileyoureout/screens/list_detail/list_detail_screen.dart';

/// Route path constants.
abstract final class AppRoutes {
  /// Dashboard (home) route.
  static const String dashboard = '/';

  /// List detail route. Expects `:listId` path parameter.
  static const String listDetail = '/list/:listId';

  /// Builds a concrete list detail path for navigation.
  static String listDetailPath(String listId) => '/list/$listId';
}

/// The application's [GoRouter] instance, exposed as a Riverpod provider so
/// that screens can read it without a [BuildContext].
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
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
