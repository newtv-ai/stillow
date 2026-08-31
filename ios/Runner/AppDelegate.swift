import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var userSounds: UserSoundChannel?

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

    let userSoundsRegistrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "StillowUserSounds"
    )
    userSounds = UserSoundChannel(messenger: userSoundsRegistrar.messenger())
  }
}

final class UserSoundChannel: NSObject, UIDocumentPickerDelegate {
  private let channel: FlutterMethodChannel
  private var pendingPick: FlutterResult?
  private var picker: UIDocumentPickerViewController?
  private var accessedURL: URL?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "com.stillow.stillow/user_sounds",
      binaryMessenger: messenger
    )
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pick":
      pick(result: result)
    case "probe":
      let arguments = call.arguments as? [String: Any]
      result(probe(bookmark: arguments?["bookmark"] as? String, path: arguments?["uri"] as? String))
    case "beginPlayback":
      let arguments = call.arguments as? [String: Any]
      beginPlayback(
        bookmark: arguments?["bookmark"] as? String,
        path: arguments?["uri"] as? String,
        result: result
      )
    case "endPlayback":
      endPlayback()
      result(nil)
    case "release":
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func pick(result: @escaping FlutterResult) {
    if pendingPick != nil {
      result(
        FlutterError(
          code: "already_picking",
          message: "A file picker is already open.",
          details: nil
        )
      )
      return
    }
    guard let controller = topViewController() else {
      result(
        FlutterError(
          code: "no_view",
          message: "Could not present the file picker.",
          details: nil
        )
      )
      return
    }
    pendingPick = result
    let picker = UIDocumentPickerViewController(
      forOpeningContentTypes: [.mp3, .mpeg4Audio],
      asCopy: false
    )
    picker.delegate = self
    picker.allowsMultipleSelection = true
    self.picker = picker
    controller.present(picker, animated: true)
  }

  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    picker = nil
    let result = pendingPick
    pendingPick = nil
    guard let result else { return }
    if urls.isEmpty {
      result(nil)
      return
    }
    var payload: [[String: Any]] = []
    for url in urls {
      if let item = filePayload(url: url) {
        payload.append(item)
      }
    }
    if payload.isEmpty {
      result(
        FlutterError(
          code: "bookmark_failed",
          message: "Could not keep access to the selected file.",
          details: nil
        )
      )
      return
    }
    result(payload)
  }

  private func filePayload(url: URL) -> [String: Any]? {
    guard url.startAccessingSecurityScopedResource() else { return nil }
    defer { url.stopAccessingSecurityScopedResource() }
    do {
      let bookmark = try url.bookmarkData(
        options: [],
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      let values = try url.resourceValues(forKeys: [.fileSizeKey, .nameKey])
      let rawName = values.name ?? url.lastPathComponent
      let fileExtension = url.pathExtension.lowercased()
      let fileName: String
      if (rawName as NSString).pathExtension.isEmpty,
         fileExtension == "mp3" || fileExtension == "m4a" {
        fileName = "\(rawName).\(fileExtension)"
      } else {
        fileName = rawName
      }
      return [
        "fileName": fileName,
        "sourcePath": url.path,
        "declaredSize": values.fileSize ?? 0,
        "accessBookmark": bookmark.base64EncodedString(),
      ]
    } catch {
      return nil
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    picker = nil
    let result = pendingPick
    pendingPick = nil
    result?(nil)
  }

  private func probe(bookmark: String?, path: String?) -> Int {
    guard let url = resolveURL(bookmark: bookmark, path: path) else { return -1 }
    let started = url.startAccessingSecurityScopedResource()
    defer {
      if started {
        url.stopAccessingSecurityScopedResource()
      }
    }
    do {
      let values = try url.resourceValues(forKeys: [.fileSizeKey])
      if let size = values.fileSize {
        return size
      }
    } catch {
      return -1
    }
    return -1
  }

  private func beginPlayback(
    bookmark: String?,
    path: String?,
    result: @escaping FlutterResult
  ) {
    endPlayback()
    guard let url = resolveURL(bookmark: bookmark, path: path) else {
      result(
        FlutterError(
          code: "resolve_failed",
          message: "Could not open the selected file.",
          details: nil
        )
      )
      return
    }
    guard url.startAccessingSecurityScopedResource() else {
      result(
        FlutterError(
          code: "access_failed",
          message: "Could not open the selected file.",
          details: nil
        )
      )
      return
    }
    accessedURL = url
    result(["path": url.path])
  }

  private func endPlayback() {
    if let accessedURL {
      accessedURL.stopAccessingSecurityScopedResource()
    }
    accessedURL = nil
  }

  private func resolveURL(bookmark: String?, path: String?) -> URL? {
    if let bookmark, let data = Data(base64Encoded: bookmark) {
      var isStale = false
      if let url = try? URL(
        resolvingBookmarkData: data,
        options: [],
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      ) {
        return url
      }
    }
    if let path, !path.isEmpty {
      return URL(fileURLWithPath: path)
    }
    return nil
  }

  private func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let window = scenes.flatMap(\.windows).first(where: \.isKeyWindow) ?? scenes.first?.windows.first
    var controller = window?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }
}
