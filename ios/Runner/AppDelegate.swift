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
        } else if call.method == "httpGet" {
          guard let args = call.arguments as? [String: Any],
                let urlString = args["url"] as? String,
                let url = URL(string: urlString) else {
            result(FlutterError(code: "invalid_arg", message: "url is required", details: nil))
            return
          }
          self.httpGet(url: url, result: result)
        } else if call.method == "httpGetBytes" {
          guard let args = call.arguments as? [String: Any],
                let urlString = args["url"] as? String,
                let url = URL(string: urlString) else {
            result(FlutterError(code: "invalid_arg", message: "url is required", details: nil))
            return
          }
          self.httpGetBytes(url: url, result: result)
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

  private func httpGet(url: URL, result: @escaping FlutterResult) {
    URLSession.shared.dataTask(with: url) { data, response, error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(code: "http_error", message: error.localizedDescription, details: nil))
          return
        }
        guard let httpResp = response as? HTTPURLResponse else {
          result(FlutterError(code: "http_error", message: "No response", details: nil))
          return
        }
        let body = data != nil ? String(data: data!, encoding: .utf8) ?? "" : ""
        result(["statusCode": httpResp.statusCode, "body": body])
      }
    }.resume()
  }

  private func httpGetBytes(url: URL, result: @escaping FlutterResult) {
    URLSession.shared.dataTask(with: url) { data, response, error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(code: "http_error", message: error.localizedDescription, details: nil))
          return
        }
        guard let httpResp = response as? HTTPURLResponse else {
          result(FlutterError(code: "http_error", message: "No response", details: nil))
          return
        }
        result(["statusCode": httpResp.statusCode, "bytes": data ?? Data()])
      }
    }.resume()
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
