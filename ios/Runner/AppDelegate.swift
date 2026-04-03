import Flutter
import UIKit
import UserNotifications
import Contacts

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.flutterplaza.pray_and_serve/contacts",
        binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { (call, result) in
        if call.method == "getEmailForContact" {
          guard let args = call.arguments as? [String: Any],
                let displayName = args["displayName"] as? String else {
            result(FlutterError(code: "invalid_arg", message: "displayName is required", details: nil))
            return
          }
          result(self.queryEmailByName(displayName))
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func queryEmailByName(_ displayName: String) -> String? {
    let store = CNContactStore()
    let predicate = CNContact.predicateForContacts(matchingName: displayName)
    do {
      let contacts = try store.unifiedContacts(
        matching: predicate,
        keysToFetch: [CNContactEmailAddressesKey as CNKeyDescriptor])
      if let first = contacts.first,
         let email = first.emailAddresses.first {
        return email.value as String
      }
    } catch {
      // Contact access denied or query failed.
    }
    return nil
  }
}
