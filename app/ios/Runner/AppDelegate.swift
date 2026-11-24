import CoreMotion
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var stepSessionHandler: StepSessionPlatformHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Flutter forwards foreground presentation and notification responses to its plugins.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // The L4 step channels are app-level platform channels, not a Flutter
    // plugin. Register them against the implicit engine before Dart starts.
    let handler = StepSessionPlatformHandler()
    handler.register(with: engineBridge.applicationRegistrar.messenger())
    stepSessionHandler = handler
  }
}

/// iOS implementation of the `steps/session` and `steps/permission` channels.
///
/// Android uses Step Detector ticks (one event per step). Core Motion exposes
/// cumulative pedometer data instead, so each positive step delta is expanded
/// into individual events to preserve the Dart collector's one-tick/one-step
/// contract. Core Motion is unavailable in the iOS Simulator; in that case the
/// channel returns a controlled NO_SENSOR error for the UI to degrade cleanly.
private final class StepSessionPlatformHandler: NSObject, FlutterStreamHandler {
  private let pedometer = CMPedometer()
  private var eventChannel: FlutterEventChannel?
  private var permissionChannel: FlutterMethodChannel?
  private var eventSink: FlutterEventSink?
  private var reportedSteps = 0
  private var isListening = false

  func register(with messenger: FlutterBinaryMessenger) {
    let eventChannel = FlutterEventChannel(
      name: "steps/session",
      binaryMessenger: messenger
    )
    eventChannel.setStreamHandler(self)
    self.eventChannel = eventChannel

    let permissionChannel = FlutterMethodChannel(
      name: "steps/permission",
      binaryMessenger: messenger
    )
    permissionChannel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "status":
        result(CMPedometer.authorizationStatus() == .authorized)
      case "openSettings":
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
          result(false)
          return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: { result($0) })
      case "request":
        self?.requestMotionPermission(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.permissionChannel = permissionChannel
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    guard CMPedometer.isStepCountingAvailable() else {
      DispatchQueue.main.async {
        events(
          FlutterError(
            code: "NO_SENSOR",
            message: "当前设备不提供 Core Motion 步数数据（模拟器通常如此）",
            details: nil
          )
        )
      }
      return nil
    }

    eventSink = events
    reportedSteps = 0
    isListening = true
    pedometer.startUpdates(from: Date()) { [weak self] data, error in
      DispatchQueue.main.async {
        guard let self, self.isListening else { return }
        if let error {
          let authorizationStatus = CMPedometer.authorizationStatus()
          let code =
            authorizationStatus == .denied || authorizationStatus == .restricted
            ? "PERMISSION_DENIED"
            : "MOTION_UNAVAILABLE"
          self.finishWithError(
            code: code,
            message: error.localizedDescription
          )
          return
        }
        guard let stepCount = data?.numberOfSteps.intValue else { return }
        let total = max(0, stepCount)
        let delta = total - self.reportedSteps
        self.reportedSteps = total
        guard delta > 0 else { return }
        let timestamp = Date().timeIntervalSince1970
        for _ in 0..<delta {
          self.eventSink?(timestamp)
        }
      }
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    stopListening()
    return nil
  }

  private func requestMotionPermission(result: @escaping FlutterResult) {
    guard CMPedometer.isStepCountingAvailable() else {
      result(false)
      return
    }
    switch CMPedometer.authorizationStatus() {
    case .denied, .restricted:
      result(false)
    default:
      // A pedometer query prompts on first use and is the supported way to
      // determine whether Motion & Fitness access is available.
      pedometer.queryPedometerData(
        from: Date(timeIntervalSinceNow: -5),
        to: Date()
      ) { data, _ in
        DispatchQueue.main.async {
          result(data != nil)
        }
      }
    }
  }

  private func finishWithError(code: String, message: String) {
    eventSink?(FlutterError(code: code, message: message, details: nil))
    stopListening()
  }

  private func stopListening() {
    isListening = false
    pedometer.stopUpdates()
    eventSink = nil
  }
}
