import 'package:domain/domain.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Concrete [NotificationService] backed by [FlutterLocalNotificationsPlugin].
///
/// Initialise once at app start via [initialize]. On iOS, notification
/// permission is requested separately (via `permission_handler`) so
/// [initialize] does not trigger the system permission dialog.
///
/// Set [notificationTapCallback] after the router is ready so that tapping a
/// notification deep-links the user to the correct list.
class FlutterNotificationService implements NotificationService {
  /// Creates a [FlutterNotificationService].
  ///
  /// An optional [plugin] may be supplied for testing; production code uses
  /// the default constructor which creates a real
  /// [FlutterLocalNotificationsPlugin].
  FlutterNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

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
  // Private helpers
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
      ),
    );
  }
}
