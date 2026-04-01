import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:whileyoureout/providers/providers.dart';
import 'package:whileyoureout/router/app_router.dart';

/// Entry point for the While You're Out app.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: _AppStartup(),
    ),
  );
}

/// Bootstraps all background services once the widget tree is ready.
///
/// Startup order is important:
/// 1. Register the notification tap callback **before** calling
///    `FlutterNotificationService.initialize` so that any cold-start payload
///    (app launched by tapping a notification) is routed correctly.
/// 2. Initialise the notification service (sets up plugin, Android channel,
///    and checks cold-start launch details).
/// 3. Start `GeofenceManager` (iOS priority-queue region swapping).
/// 4. Start `GeofenceEventHandler` (entry event → notification pipeline).
class _AppStartup extends ConsumerStatefulWidget {
  const _AppStartup();

  @override
  ConsumerState<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends ConsumerState<_AppStartup> {
  @override
  void initState() {
    super.initState();
    // Defer startup until after the first frame so that all providers are
    // fully initialised and the router is accessible.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Read services and use-cases once; these are singletons for the app
      // lifetime backed by Riverpod providers.
      final notificationService = ref.read(notificationServiceProvider);
      final router = ref.read(appRouterProvider);

      // 1. Register the tap callback FIRST so that a cold-start payload
      //    (delivered inside initialize → _handleColdStartLaunch) is handled
      //    immediately rather than being dropped.
      notificationService.notificationTapCallback =
          (listId) => router.go(AppRoutes.listDetailPath(listId));

      // 2. Initialise flutter_local_notifications, create the Android channel,
      //    and handle any cold-start notification payload.
      await notificationService.initialize();

      // 3. Start iOS region priority-queue manager (no-op on Android).
      ref.read(geofenceManagerProvider).start();

      // 4. Start the geofence-entry → notification pipeline.
      ref.read(geofenceEventHandlerProvider).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const App();
  }
}

/// Root application widget.
class App extends ConsumerWidget {
  /// Creates the root [App] widget.
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: "While You're Out",
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
