import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let mapsKey = Bundle.main.object(
      forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY"
    ) as? String ?? ""
    GMSServices.provideAPIKey(mapsKey)
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = self.registrar(forPlugin: "GeofencingHandler") {
      GeofencingHandler.register(with: registrar)
    }
    if let registrar = self.registrar(forPlugin: "BackupExclusionHandler") {
      BackupExclusionHandler.register(with: registrar)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
