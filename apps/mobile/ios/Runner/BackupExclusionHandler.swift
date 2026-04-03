import Flutter
import Foundation

/// Handles the "com.yourcompany.whileyoureout/backup_exclusion" method channel.
///
/// Exposes a single method `excludeFromBackup(path: String)` that sets
/// `NSURLIsExcludedFromBackupKey = true` on the given file URL so the file is
/// not synced to iCloud.
class BackupExclusionHandler: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.yourcompany.whileyoureout/backup_exclusion",
            binaryMessenger: registrar.messenger()
        )
        let instance = BackupExclusionHandler()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "excludeFromBackup":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String else {
                result(FlutterError(
                    code: "INVALID_ARGS",
                    message: "Expected {path: String}",
                    details: nil
                ))
                return
            }
            do {
                var url = URL(fileURLWithPath: path)
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = true
                try url.setResourceValues(resourceValues)
                result(nil) // success
            } catch {
                result(FlutterError(
                    code: "EXCLUSION_FAILED",
                    message: error.localizedDescription,
                    details: nil
                ))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
