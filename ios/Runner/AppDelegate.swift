import Flutter
import UIKit
import UniformTypeIdentifiers
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var nativeChannels: NativeChannels?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets flutter_local_notifications show reminders and handle their taps.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    nativeChannels = NativeChannels(messenger: engineBridge.applicationRegistrar.messenger())
  }
}

/// iOS side of the app's own method channels; MainActivity.kt is the Android
/// one. `zenith/system_colors` is Android only: Dart falls back on its own.
final class NativeChannels: NSObject, UIDocumentPickerDelegate,
  UIDocumentInteractionControllerDelegate
{
  // Pending Dart call waiting for a document picker to return.
  private var pendingResult: FlutterResult?
  private var pendingIsSave = false

  // Kept alive while its preview or menu is on screen.
  private var interaction: UIDocumentInteractionController?
  private var previewHost: UIViewController?

  init(messenger: FlutterBinaryMessenger) {
    super.init()
    FlutterMethodChannel(name: "zenith/file_opener", binaryMessenger: messenger)
      .setMethodCallHandler { [weak self] call, result in
        guard call.method == "open" else { return result(FlutterMethodNotImplemented) }
        guard let path = (call.arguments as? [String: Any])?["path"] as? String else {
          return result(FlutterError(code: "BAD_ARGS", message: "Missing 'path'", details: nil))
        }
        self?.open(URL(fileURLWithPath: path), result: result)
      }
    FlutterMethodChannel(name: "zenith/backup_files", binaryMessenger: messenger)
      .setMethodCallHandler { [weak self] call, result in
        guard let self else { return }
        switch call.method {
        case "saveAs":
          // The file is already named as Dart wants it saved.
          guard let path = (call.arguments as? [String: Any])?["path"] as? String else {
            return result(FlutterError(code: "BAD_ARGS", message: "Missing 'path'", details: nil))
          }
          let picker = UIDocumentPickerViewController(
            forExporting: [URL(fileURLWithPath: path)], asCopy: true)
          self.present(picker, isSave: true, result: result)
        case "pick":
          // Backups can come back from other apps with odd types; the Dart
          // side validates the content.
          let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.item], asCopy: true)
          self.present(picker, isSave: false, result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
  }

  private var presenter: UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { ($0 as? UIWindowScene)?.keyWindow }.first
    var top = window?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
  }

  // MARK: Backup files

  private func present(
    _ picker: UIDocumentPickerViewController, isSave: Bool, result: @escaping FlutterResult
  ) {
    guard pendingResult == nil else {
      return result(FlutterError(code: "BUSY", message: "A file picker is already open", details: nil))
    }
    guard let presenter else {
      return result(FlutterError(code: "NO_APP", message: "No window to show the picker in", details: nil))
    }
    pendingResult = result
    pendingIsSave = isSave
    picker.delegate = self
    presenter.present(picker, animated: true)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    let result = pendingResult
    pendingResult = nil
    // A pick is a copy in the app's tmp folder: Dart reads it, then deletes it.
    result?(pendingIsSave ? true : urls.first?.path)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    let result = pendingResult
    pendingResult = nil
    result?(pendingIsSave ? false : nil)
  }

  // MARK: File opener

  private func open(_ url: URL, result: FlutterResult) {
    guard FileManager.default.fileExists(atPath: url.path) else {
      return result(FlutterError(code: "NOT_FOUND", message: "File not found: \(url.path)", details: nil))
    }
    guard let presenter else {
      return result(FlutterError(code: "NO_APP", message: "No window to show the file in", details: nil))
    }
    let controller = UIDocumentInteractionController(url: url)
    controller.delegate = self
    interaction = controller
    previewHost = presenter
    // Quick Look first; the "Open in…" menu for types it can't preview.
    if controller.presentPreview(animated: true)
      || controller.presentOptionsMenu(from: presenter.view.bounds, in: presenter.view, animated: true)
    {
      result(true)
    } else {
      interaction = nil
      previewHost = nil
      result(FlutterError(code: "NO_APP", message: "No app found to open this file", details: nil))
    }
  }

  func documentInteractionControllerViewControllerForPreview(
    _ controller: UIDocumentInteractionController
  ) -> UIViewController {
    previewHost ?? UIViewController()
  }

  func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
    interaction = nil
    previewHost = nil
  }

  func documentInteractionControllerDidDismissOptionsMenu(_ controller: UIDocumentInteractionController) {
    interaction = nil
    previewHost = nil
  }
}
