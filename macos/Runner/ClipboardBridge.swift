import ApplicationServices
import Carbon.HIToolbox
import Cocoa
import FlutterMacOS

/// Everything that touches macOS: watching the pasteboard, showing and hiding
/// the panel, and synthesising the paste keystroke.
///
/// Dart owns the list and the pixels; this owns the system.
final class ClipboardBridge {
  private let channel: FlutterMethodChannel
  private let pasteboard = NSPasteboard.general
  private weak var window: MainFlutterWindow?

  private var lastChangeCount: Int
  private var timer: Timer?
  private var resignObserver: NSObjectProtocol?

  /// Mirrors what Dart has been told, so the panel's contents can be torn down
  /// while it is hidden instead of sitting there animating a text cursor.
  private var panelVisible = false

  /// Whichever app was frontmost when the panel opened, so the paste lands
  /// back where the user actually was.
  private weak var previousApp: NSRunningApplication?

  init(messenger: FlutterBinaryMessenger, window: MainFlutterWindow) {
    self.channel = FlutterMethodChannel(
      name: "copy_paste/clipboard", binaryMessenger: messenger)
    self.window = window
    self.lastChangeCount = pasteboard.changeCount

    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "paste":
        if let text = call.arguments as? String { self?.paste(text) }
        result(nil)
      case "hide":
        self?.hidePanel()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    startMonitoring()

    // `hidesOnDeactivate` dismisses the panel behind our back when the user
    // clicks elsewhere, so this is the only way to learn about that path.
    resignObserver = NotificationCenter.default.addObserver(
      forName: NSApplication.didResignActiveNotification,
      object: nil, queue: .main
    ) { [weak self] _ in
      self?.setPanelVisible(false)
    }
  }

  deinit {
    timer?.invalidate()
    if let resignObserver { NotificationCenter.default.removeObserver(resignObserver) }
  }

  // MARK: - Capture

  /// macOS has no clipboard-change notification — comparing `changeCount` is
  /// the only mechanism that exists, so this is the one place the app polls.
  ///
  /// Reading a single Int twice a second is negligible. The tolerance is the
  /// part that matters: it lets the kernel coalesce this wakeup with others
  /// rather than waking the CPU on its own schedule.
  private func startMonitoring() {
    let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
      self?.pollPasteboard()
    }
    timer.tolerance = 0.2
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  private func pollPasteboard() {
    let count = pasteboard.changeCount
    guard count != lastChangeCount else { return }
    lastChangeCount = count

    guard let text = pasteboard.string(forType: .string), !text.isEmpty else { return }
    channel.invokeMethod("onCopy", arguments: text)
  }

  // MARK: - Panel

  func showPanel() {
    guard let window else { return }

    let front = NSWorkspace.shared.frontmostApplication
    if front?.bundleIdentifier != Bundle.main.bundleIdentifier {
      previousApp = front
    }

    // Told first so Dart has a head start building the list before the window
    // is actually on screen.
    setPanelVisible(true)
    window.positionOnActiveScreen()
    activateSelf()
    window.makeKeyAndOrderFront(nil)
  }

  func hidePanel() {
    window?.orderOut(nil)
    setPanelVisible(false)
    _ = previousApp?.activate(options: [])
  }

  private func setPanelVisible(_ visible: Bool) {
    guard panelVisible != visible else { return }
    panelVisible = visible
    channel.invokeMethod(visible ? "onShow" : "onHide", arguments: nil)
  }

  func togglePanel() {
    if window?.isVisible == true {
      hidePanel()
    } else {
      showPanel()
    }
  }

  func clearHistory() {
    channel.invokeMethod("onClear", arguments: nil)
  }

  // MARK: - Paste

  /// Order matters here. Getting it wrong sends the paste to the wrong app, or
  /// nowhere at all.
  private func paste(_ text: String) {
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
    // Our own write must not come back around as a new history entry.
    lastChangeCount = pasteboard.changeCount

    window?.orderOut(nil)
    setPanelVisible(false)
    _ = previousApp?.activate(options: [])

    // Focus restoration is asynchronous, so the keystroke has to land after it.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      Self.sendCommandV()
    }
  }

  private static func sendCommandV() {
    // Without Accessibility this fails silently, which looks like the app is
    // simply broken. Checking first at least makes the cause diagnosable.
    guard AXIsProcessTrusted() else {
      NSLog("copy_paste: paste skipped — Accessibility permission not granted")
      return
    }

    let source = CGEventSource(stateID: .combinedSessionState)
    let v = CGKeyCode(kVK_ANSI_V)
    guard let down = CGEvent(keyboardEventSource: source, virtualKey: v, keyDown: true),
      let up = CGEvent(keyboardEventSource: source, virtualKey: v, keyDown: false)
    else { return }

    down.flags = .maskCommand
    up.flags = .maskCommand
    down.post(tap: .cgAnnotatedSessionEventTap)
    up.post(tap: .cgAnnotatedSessionEventTap)
  }

  private func activateSelf() {
    if #available(macOS 14.0, *) {
      NSApp.activate()
    } else {
      NSApp.activate(ignoringOtherApps: true)
    }
  }
}
