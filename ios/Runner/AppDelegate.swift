import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Widget data channel — writes balance summary to App Group UserDefaults
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.jphermans.ai-balance-tracker/widget",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] (call, result) in
        if call.method == "updateWidget" {
          self?.handleWidgetUpdate(call: call, result: result)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleWidgetUpdate(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let defaults = UserDefaults(suiteName: "group.com.jphermans.ai-balance-tracker") else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments or App Group", details: nil))
      return
    }
    defaults.set(args["totalBalance"] as? Double ?? 0, forKey: "widget_total_balance")
    defaults.set(args["providerCount"] as? Int ?? 0, forKey: "widget_provider_count")
    defaults.set(args["currency"] as? String ?? "USD", forKey: "widget_currency")
    defaults.set(args["lastUpdated"] as? Int ?? 0, forKey: "widget_last_updated")
    defaults.synchronize()
    result(true)
  }
}
