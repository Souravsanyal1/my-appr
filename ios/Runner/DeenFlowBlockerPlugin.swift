import Flutter
import UIKit
#if canImport(FamilyControls)
import FamilyControls
#endif
#if canImport(ManagedSettings)
import ManagedSettings
#endif
#if canImport(DeviceActivity)
import DeviceActivity
#endif

public class DeenFlowBlockerPlugin: NSObject, FlutterPlugin {
    
    private static let channelName = "com.focusdeen.app/methods"
    private static let appGroupId = "group.com.focusdeen.app"
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        let instance = DeenFlowBlockerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestAuthorization", "checkPermissions":
            if #available(iOS 16.0, *) {
                #if canImport(FamilyControls)
                Task {
                    do {
                        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                        DispatchQueue.main.async {
                            result([
                                "accessibility": false,
                                "usageStats": true,
                                "overlay": false,
                                "notifications": true,
                                "familyControls": true
                            ])
                        }
                    } catch {
                        DispatchQueue.main.async {
                            result([
                                "familyControls": false,
                                "error": error.localizedDescription
                            ])
                        }
                    }
                }
                #else
                result(["familyControls": false, "supported": false])
                #endif
            } else {
                result(["familyControls": false, "supported": false])
            }
            
        case "setTemporaryUnlock":
            guard let args = call.arguments as? [String: Any],
                  let durationMinutes = args["durationMinutes"] as? Int else {
                result(FlutterError(code: "INVALID_ARGS", message: "Duration required", details: nil))
                return
            }
            
            if #available(iOS 16.0, *) {
                let userDefaults = UserDefaults(suiteName: DeenFlowBlockerPlugin.appGroupId)
                let expiresAt = Date().addingTimeInterval(TimeInterval(durationMinutes * 60))
                userDefaults?.set(expiresAt.timeIntervalSince1970, forKey: "unlockedUntil")
                
                #if canImport(ManagedSettings)
                let store = ManagedSettingsStore()
                store.shield.applications = nil
                #endif
                
                result(true)
            } else {
                result(false)
            }
            
        case "removeTemporaryUnlock", "lockNow":
            if #available(iOS 16.0, *) {
                let userDefaults = UserDefaults(suiteName: DeenFlowBlockerPlugin.appGroupId)
                userDefaults?.removeObject(forKey: "unlockedUntil")
                result(true)
            } else {
                result(false)
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
