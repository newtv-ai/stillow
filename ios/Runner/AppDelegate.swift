import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "StillowPrivateStorage"
    )
    let channel = FlutterMethodChannel(
      name: "com.stillow.stillow/private_storage",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "excludeFromBackup",
            let arguments = call.arguments as? [String: Any],
            let path = arguments["path"] as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      var url = URL(fileURLWithPath: path, isDirectory: true)
      do {
        try url.setResourceValues(values)
        result(nil)
      } catch {
        result(
          FlutterError(
            code: "backup_exclusion_failed",
            message: "Could not exclude Stillow private data from backup.",
            details: error.localizedDescription
          )
        )
      }
    }
  }
}
