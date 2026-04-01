import CoreLocation
import Flutter
import UIKit

/// Flutter plugin that bridges iOS CLLocationManager circular region monitoring
/// to the Dart platform channel.
///
/// Method channel: `com.yourcompany.whileyoureout/geofencing`
/// Event channel:  `com.yourcompany.whileyoureout/geofencing/events`
class GeofencingHandler: NSObject, CLLocationManagerDelegate, FlutterPlugin, FlutterStreamHandler {

  private let locationManager = CLLocationManager()
  private var eventSink: FlutterEventSink?

  static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(
      name: "com.yourcompany.whileyoureout/geofencing",
      binaryMessenger: registrar.messenger()
    )
    let eventChannel = FlutterEventChannel(
      name: "com.yourcompany.whileyoureout/geofencing/events",
      binaryMessenger: registrar.messenger()
    )
    let instance = GeofencingHandler()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
  }

  override init() {
    super.init()
    locationManager.delegate = self
    locationManager.allowsBackgroundLocationUpdates = true
    locationManager.pausesLocationUpdatesAutomatically = true
    locationManager.requestAlwaysAuthorization()
  }

  // MARK: FlutterPlugin

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      // unregisterAll has no args
      if call.method == "unregisterAll" {
        for region in locationManager.monitoredRegions {
          locationManager.stopMonitoring(for: region)
        }
        result(nil)
        return
      }
      result(FlutterError(code: "INVALID_ARGS", message: "Expected a dictionary", details: nil))
      return
    }

    switch call.method {
    case "registerRegion":
      guard
        let id = args["id"] as? String,
        let latitude = args["latitude"] as? Double,
        let longitude = args["longitude"] as? Double,
        let radius = args["radius"] as? Double
      else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing required fields", details: nil))
        return
      }
      let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      let clampedRadius = max(100.0, min(radius, 5000.0))
      let region = CLCircularRegion(center: center, radius: clampedRadius, identifier: id)
      let triggerString = args["trigger"] as? String ?? "enter"
      region.notifyOnEntry = triggerString == "enter" || triggerString == "enterAndExit"
      region.notifyOnExit  = triggerString == "exit"  || triggerString == "enterAndExit"
      locationManager.startMonitoring(for: region)
      result(nil)

    case "unregisterRegion":
      guard let id = args["id"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing id", details: nil))
        return
      }
      for region in locationManager.monitoredRegions where region.identifier == id {
        locationManager.stopMonitoring(for: region)
      }
      result(nil)

    case "unregisterAll":
      for region in locationManager.monitoredRegions {
        locationManager.stopMonitoring(for: region)
      }
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: FlutterStreamHandler

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  // MARK: CLLocationManagerDelegate

  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    sendEvent(regionId: region.identifier, type: "enter")
  }

  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    sendEvent(regionId: region.identifier, type: "exit")
  }

  func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
    eventSink?(FlutterError(code: "MONITORING_FAILED", message: error.localizedDescription, details: region?.identifier))
  }

  // MARK: Private helpers

  private func sendEvent(regionId: String, type: String) {
    let formatter = ISO8601DateFormatter()
    eventSink?([
      "regionId": regionId,
      "type": type,
      "timestamp": formatter.string(from: Date())
    ])
  }
}
