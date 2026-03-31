/// Abstract OS-level notification service.
///
/// Implemented by the `notifications` package.
abstract class NotificationService {
  /// Performs any one-time initialisation required by the underlying platform.
  ///
  /// Must be called before any other method on this service.
  Future<void> initialize();

  /// Posts a local notification informing the user that [listTitle] has
  /// [incompleteCount] items still to do.
  ///
  /// The [listId] is included so that tapping the notification can deep-link
  /// directly to the correct list.
  Future<void> postListNotification({
    required String listId,
    required String listTitle,
    required int incompleteCount,
  });

  /// Requests notification permission from the OS.
  ///
  /// Returns `true` if permission was granted, `false` otherwise.
  Future<bool> requestPermission();
}
