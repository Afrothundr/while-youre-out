import 'dart:io';

import 'package:flutter/services.dart';

/// Service that marks a file as excluded from iCloud / device backup.
///
/// On iOS, calls through a [MethodChannel] to set
/// `NSURLIsExcludedFromBackupKey = true` on the file URL.
///
/// On other platforms, this is a no-op (Android does not back up app-private
/// SQLite files to cloud by default, and the desktop targets do not apply).
class BackupExclusionService {
  const BackupExclusionService();

  static const _channel = MethodChannel(
    'com.yourcompany.whileyoureout/backup_exclusion',
  );

  /// Marks the file at [path] as excluded from backup.
  ///
  /// Silently ignores errors (missing platform implementation, file not found,
  /// etc.) so the app never crashes because of a backup hint.
  Future<void> excludeFromBackup(String path) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('excludeFromBackup', {'path': path});
    } on PlatformException catch (e) {
      // Best-effort; log in debug but do not surface to the user.
      assert(() {
        // ignore: avoid_print
        print('[BackupExclusionService] excludeFromBackup failed: $e');
        return true;
      }());
    }
  }
}
