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

/// Starts the geofence manager once the widget tree is built.
class _AppStartup extends ConsumerStatefulWidget {
  const _AppStartup();

  @override
  ConsumerState<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends ConsumerState<_AppStartup> {
  @override
  void initState() {
    super.initState();
    // Start geofence manager after the first frame so providers are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(geofenceManagerProvider).start();
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
