import 'dart:io';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Quiet-hours preference keys (must match NotificationSettingsScreen)
// ---------------------------------------------------------------------------

/// Shared-preference keys for quiet-hours configuration.
///
/// These constants are intentionally duplicated here (rather than imported
/// from the mobile app) so the `notifications` package remains self-contained
/// and testable without depending on app-layer code.
abstract final class _QuietHoursPrefs {
  static const String enabled = 'quiet_hours_enabled';
  static const String start = 'quiet_hours_start';
  static const String end = 'quiet_hours_end';
}

// ---------------------------------------------------------------------------
// Android notification group key
// ---------------------------------------------------------------------------

const String _kGroupKey = 'com.yourcompany.whileyoureout.geofence_group';

/// Stable notification ID reserved for the Android group summary.
const int _kSummaryId = 0;

/// Concrete [NotificationService] backed by [FlutterLocalNotificationsPlugin].
///
/// Initialise once at app start via [initialize]. On iOS, notification
/// permission is requested separately (via `permission_handler`) so
/// [initialize] does not trigger the system permission dialog.
///
/// Set [notificationTapCallback] after the router is ready so that tapping a
/// notification deep-links the user to the correct list.
///
/// **Quiet hours**: notifications are silently suppressed when the current
/// wall-clock time falls inside the window persisted in [SharedPreferences]
/// under the [_QuietHoursPrefs] keys. Overnight ranges (start > end) are
/// handled correctly.
///
/// **Android grouping**: individual notifications share a group key so the
/// system stacks them. A summary notification is posted automatically on
/// Android when more than one geofence notification is active.
class FlutterNotificationService implements NotificationService {
  /// Creates a [FlutterNotificationService].
  ///
  /// An optional [plugin] may be supplied for testing; production code uses
  /// the default constructor which creates a real
  /// [FlutterLocalNotificationsPlugin].
  FlutterNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    TimeOfDay Function()? nowProvider,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _nowProvider = nowProvider ?? TimeOfDay.now;

  final FlutterLocalNotificationsPlugin _plugin;

  /// Returns the current [TimeOfDay]. Overridable in tests for determinism.
  final TimeOfDay Function() _nowProvider;

  /// Called with the `listId` payload whenever the user taps a notification
  /// posted by this service.
  ///
  /// Assign this after the router is ready so that navigation can be performed
  /// immediately. Replaces any previously assigned callback.
  void Function(String listId)? notificationTapCallback;

  // ---------------------------------------------------------------------------
  // NotificationService
  // ---------------------------------------------------------------------------

  @override
  Future<void> initialize() async {
    const iosSettings = DarwinInitializationSettings(
      // Permission is requested separately via permission_handler so that we
      // can show our own explanation screen before the OS dialog appears.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(
        iOS: iosSettings,
        android: androidSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create the Android notification channel so that notifications are
    // categorised correctly in the system settings.
    await _createAndroidChannel();

    // Handle the case where the app was launched cold by tapping a
    // notification — forward the payload to the registered tap callback.
    await _handleColdStartLaunch();
  }

  @override
  Future<void> postListNotification({
    required String listId,
    required String listTitle,
    required int incompleteCount,
  }) async {
    // ------------------------------------------------------------------
    // Quiet hours gate — suppress silently if the current time is inside
    // the configured window.
    // ------------------------------------------------------------------
    if (await _isInQuietHours()) return;

    final body = incompleteCount == 1
        ? '1 item remaining'
        : '$incompleteCount items remaining';

    await _plugin.show(
      // Stable integer ID derived from the list ID so that repeated entry
      // events for the same list update the existing notification rather than
      // stacking new ones.
      listId.hashCode,
      listTitle,
      body,
      _notificationDetails(),
      // The listId is the payload — used by the tap handler to deep-link.
      payload: listId,
    );

    // ------------------------------------------------------------------
    // Android group summary — post after the individual notification so
    // that the system has at least two items to group.
    // ------------------------------------------------------------------
    if (Platform.isAndroid) {
      await _postAndroidGroupSummary();
    }
  }

  @override
  Future<bool> requestPermission() async {
    // On iOS, request via the flutter_local_notifications iOS implementation.
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // On Android 13+ the plugin handles the permission request internally
    // when a notification is first posted, so we return true as a best-effort
    // answer for non-iOS platforms.
    return granted ?? true;
  }

  // ---------------------------------------------------------------------------
  // Private helpers — quiet hours
  // ---------------------------------------------------------------------------

  /// Returns `true` when the current time falls inside the configured quiet
  /// window.
  ///
  /// Handles both same-day ranges (start < end) and overnight ranges
  /// (start > end, e.g. 22:00 → 07:00).
  Future<bool> _isInQuietHours() async {
    final prefs = await SharedPreferences.getInstance();
    final quietEnabled = prefs.getBool(_QuietHoursPrefs.enabled) ?? false;
    if (!quietEnabled) return false;

    final now = _nowProvider();
    final nowMinutes = now.hour * 60 + now.minute;
    final start = prefs.getInt(_QuietHoursPrefs.start) ?? 1320; // 22:00
    final end = prefs.getInt(_QuietHoursPrefs.end) ?? 420; // 07:00

    // Overnight range: start > end (e.g. 22:00 to 07:00 crosses midnight).
    if (start > end) {
      return nowMinutes >= start || nowMinutes < end;
    }

    // Same-day range (e.g. 13:00 to 14:00).
    return nowMinutes >= start && nowMinutes < end;
  }

  // ---------------------------------------------------------------------------
  // Private helpers — Android grouping
  // ---------------------------------------------------------------------------

  /// Posts (or refreshes) the Android group summary notification.
  ///
  /// The summary is always posted with a fixed [_kSummaryId] so it replaces
  /// itself rather than accumulating.
  Future<void> _postAndroidGroupSummary() async {
    await _plugin.show(
      _kSummaryId,
      "While You're Out",
      'Multiple location reminders',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'geofence_alerts',
          'Location Reminders',
          channelDescription:
              'Notifications when you arrive at a saved location',
          groupKey: _kGroupKey,
          setAsGroupSummary: true,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers — general
  // ---------------------------------------------------------------------------

  /// Creates the Android notification channel used for geofence alerts.
  ///
  /// Safe to call repeatedly — Android is idempotent for channels with the
  /// same ID.
  Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      'geofence_alerts',
      'Location Reminders',
      description: 'Notifications when you arrive at a saved location',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Checks whether the app was launched by the user tapping a notification
  /// (cold-start scenario) and, if so, forwards the payload to
  /// [notificationTapCallback].
  Future<void> _handleColdStartLaunch() async {
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final listId = launchDetails?.notificationResponse?.payload;
      if (listId != null) {
        notificationTapCallback?.call(listId);
      }
    }
  }

  /// Called by the plugin whenever the user taps a notification while the app
  /// is in the foreground or background (but not terminated).
  void _onNotificationTapped(NotificationResponse response) {
    final listId = response.payload;
    if (listId != null) {
      notificationTapCallback?.call(listId);
    }
  }

  /// Returns platform-specific [NotificationDetails] for geofence alert
  /// notifications.
  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      iOS: DarwinNotificationDetails(
        categoryIdentifier: 'geofence_alert',
      ),
      android: AndroidNotificationDetails(
        'geofence_alerts',
        'Location Reminders',
        channelDescription:
            'Notifications when you arrive at a saved location',
        importance: Importance.high,
        priority: Priority.high,
        groupKey: _kGroupKey,
      ),
    );
  }
}
