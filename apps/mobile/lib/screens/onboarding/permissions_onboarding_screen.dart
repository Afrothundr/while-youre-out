import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Signature for a function that requests a [Permission] and returns its
/// resulting [PermissionStatus].
typedef RequestPermissionCallback = Future<PermissionStatus> Function(
  Permission permission,
);

/// Signature for a function that checks the current status of a [Permission]
/// without triggering a system prompt.
typedef CheckPermissionStatusCallback = Future<PermissionStatus> Function(
  Permission permission,
);

/// Signature for the navigation callback used when onboarding completes.
typedef OnOnboardingCompleteCallback = void Function(BuildContext context);

/// Default implementation of [RequestPermissionCallback] that calls the real
/// permission_handler platform channel.
Future<PermissionStatus> _defaultRequestPermission(
  Permission permission,
) =>
    permission.request();

/// Default implementation of [CheckPermissionStatusCallback] that reads the
/// current permission status via the real permission_handler platform channel.
Future<PermissionStatus> _defaultCheckPermissionStatus(
  Permission permission,
) =>
    permission.status;

/// Default implementation of [OnOnboardingCompleteCallback] that navigates to
/// the dashboard using GoRouter.
void _defaultOnComplete(BuildContext context) => context.go('/');

// ---------------------------------------------------------------------------

/// A one-time onboarding screen that requests location and notification
/// permissions.
///
/// Shown on first launch if `onboarding_complete` is not set in
/// [SharedPreferences]. Consists of three pages in a [PageView]:
///
/// 1. **When-in-use** — requests [Permission.locationWhenInUse].
/// 2. **Always on** — requests [Permission.locationAlways].
/// 3. **Notifications** — requests [Permission.notification].
///
/// After step 3 (regardless of whether permissions were granted),
/// `onboarding_complete` is written to `true` and [onComplete] is called
/// (defaults to `context.go('/')`).
///
/// The [requestPermission] and [onComplete] parameters are injectable for
/// testing.
class PermissionsOnboardingScreen extends StatefulWidget {
  /// Creates a [PermissionsOnboardingScreen].
  const PermissionsOnboardingScreen({
    super.key,
    RequestPermissionCallback? requestPermission,
    CheckPermissionStatusCallback? checkPermissionStatus,
    OnOnboardingCompleteCallback? onComplete,
  })  : requestPermission = requestPermission ?? _defaultRequestPermission,
        checkPermissionStatus =
            checkPermissionStatus ?? _defaultCheckPermissionStatus,
        onComplete = onComplete ?? _defaultOnComplete;

  /// Callback used to request a platform permission.
  ///
  /// Injectable for testing. Defaults to the real permission_handler call.
  final RequestPermissionCallback requestPermission;

  /// Callback used to check the current status of a platform permission
  /// without triggering a system prompt.
  ///
  /// Injectable for testing. Defaults to the real permission_handler call.
  final CheckPermissionStatusCallback checkPermissionStatus;

  /// Called once onboarding is finished (SharedPreferences flag is already
  /// set before this fires).
  ///
  /// Injectable for testing. Defaults to `context.go('/')`.
  final OnOnboardingCompleteCallback onComplete;

  @override
  State<PermissionsOnboardingScreen> createState() =>
      _PermissionsOnboardingScreenState();
}

class _PermissionsOnboardingScreenState
    extends State<PermissionsOnboardingScreen> {
  final PageController _pageController = PageController();

  /// Whether the user denied when-in-use permission on step 1.
  bool _whenInUseDenied = false;

  /// Whether the user denied always-on permission on step 2.
  bool _alwaysDenied = false;

  /// Whether the user denied notification permission on step 3.
  bool _notificationDenied = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Shows a dialog explaining that location access is permanently denied and
  /// offering to open the app's system settings page.
  void _showPermanentlyDeniedDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Location permission required'),
        content: const Text(
          'Please enable location access in your device Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestWhenInUse() async {
    // If permanently denied, show the settings dialog and stay on step 1.
    final currentStatus =
        await widget.checkPermissionStatus(Permission.locationWhenInUse);
    if (currentStatus.isPermanentlyDenied) {
      if (mounted) _showPermanentlyDeniedDialog();
      return;
    }

    final status =
        await widget.requestPermission(Permission.locationWhenInUse);
    if (mounted) {
      setState(() {
        _whenInUseDenied = status.isDenied || status.isPermanentlyDenied;
      });
    }
    // Advance to step 2 regardless of result.
    await _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _requestAlways() async {
    final status = await widget.requestPermission(Permission.locationAlways);
    if (!mounted) return;
    // If granted (or limited on iOS), advance to the notification step
    // immediately without showing the denial warning.
    if (!status.isDenied && !status.isPermanentlyDenied) {
      await _advanceToNotifications();
      return;
    }
    setState(() {
      _alwaysDenied = true;
    });
    // User will see the denied warning + "Continue" button which calls
    // _advanceToNotifications via onDone.
  }

  /// Advances from step 2 to step 3 (notification permission).
  Future<void> _advanceToNotifications() async {
    await _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _requestNotification() async {
    final status = await widget.requestPermission(Permission.notification);
    if (!mounted) return;
    // If granted (or limited on iOS), finish onboarding immediately.
    if (!status.isDenied && !status.isPermanentlyDenied) {
      await _finish();
      return;
    }
    setState(() {
      _notificationDenied = true;
    });
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) widget.onComplete(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          // Prevent swipe navigation — user must tap the buttons.
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _WhenInUsePage(
              denied: _whenInUseDenied,
              onContinue: _requestWhenInUse,
            ),
            _AlwaysOnPage(
              denied: _alwaysDenied,
              onRequestAlways: _requestAlways,
              // "Not now" / "Done" advances to the notification step instead
              // of finishing outright.
              onDone: _advanceToNotifications,
            ),
            _NotificationsPage(
              denied: _notificationDenied,
              onRequestNotifications: _requestNotification,
              onDone: _finish,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 — When In Use
// ---------------------------------------------------------------------------

class _WhenInUsePage extends StatelessWidget {
  const _WhenInUsePage({
    required this.denied,
    required this.onContinue,
  });

  final bool denied;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(
            Icons.location_on,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Show your location on the map',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'We use your location to center the map when you set a reminder '
            'spot.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (denied) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'You can set locations manually by tapping the map.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onContinue,
              child: const Text('Continue'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 — Always On
// ---------------------------------------------------------------------------

class _AlwaysOnPage extends StatelessWidget {
  const _AlwaysOnPage({
    required this.denied,
    required this.onRequestAlways,
    required this.onDone,
  });

  final bool denied;
  final VoidCallback onRequestAlways;

  /// Called when the user skips or acknowledges this step.
  ///
  /// Navigates to the next onboarding page (notifications) rather than
  /// finishing onboarding.
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications_active,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Icon(
                  Icons.location_on,
                  size: 32,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Get notified when you arrive',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'To remind you when you arrive at a saved location, we need '
            'background location access. Your location is never sent anywhere '
            '— everything stays on your device.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (denied) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Arrival reminders won't work without background "
                      'location. You can enable it later in Settings.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          if (!denied) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onRequestAlways,
                child: const Text('Allow Background Location'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onDone,
                child: const Text('Not now'),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onDone,
                child: const Text('Continue'),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3 — Notifications
// ---------------------------------------------------------------------------

class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage({
    required this.denied,
    required this.onRequestNotifications,
    required this.onDone,
  });

  final bool denied;
  final VoidCallback onRequestNotifications;

  /// Called when the user skips or acknowledges the denial — finishes
  /// onboarding.
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(
            Icons.notifications_outlined,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Stay in the loop',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "We'll notify you when you arrive at a saved location so you "
            "don't forget a thing.",
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (denied) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Notifications are disabled. You can enable them later in '
                'your device Settings.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const Spacer(),
          if (!denied) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onRequestNotifications,
                child: const Text('Allow Notifications'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onDone,
                child: const Text('Not now'),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onDone,
                child: const Text('Done'),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
