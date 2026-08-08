import ApplicationServices
import Carbon.HIToolbox
import Cocoa
import FlutterMacOS
import ServiceManagement

@main
class AppDelegate: FlutterAppDelegate {
  private var bridge: ClipboardBridge?
  private var hotKey: HotKey?
  private var statusItem: NSStatusItem?
  private var launchAtLoginItem: NSMenuItem?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    guard let window = mainFlutterWindow as? MainFlutterWindow,
      let controller = window.contentViewController as? FlutterViewController
    else {
      NSLog("copy_paste: no Flutter window; nothing to attach to")
      return
    }

    bridge = ClipboardBridge(
      messenger: controller.engine.binaryMessenger, window: window)

    // Starts hidden — the panel is summoned, not launched into.
    window.orderOut(nil)

    setUpStatusItem()

    hotKey = HotKey(
      keyCode: UInt32(kVK_ANSI_V),
      modifiers: UInt32(cmdKey | shiftKey)
    ) { [weak self] in
      self?.bridge?.togglePanel()
    }
    if hotKey == nil {
      NSLog("copy_paste: ⌘⇧V is already taken; use the menu bar item instead")
    }

    promptForAccessibilityIfNeeded()
  }

  /// Hiding the panel must never quit a background utility.
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  /// Opening an already-running background app from Finder otherwise appears
  /// to do nothing at all, which reads as the app being broken.
  override func applicationShouldHandleReopen(
    _ sender: NSApplication, hasVisibleWindows flag: Bool
  ) -> Bool {
    bridge?.showPanel()
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // MARK: - Menu bar

  /// With `LSUIElement` there is no Dock icon and no application menu, so
  /// without this the app would have no way to be quit or discovered.
  private func setUpStatusItem() {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    item.button?.image = NSImage(
      systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard")

    let menu = NSMenu()
    menu.delegate = self
    menu.addItem(menuItem("Show", #selector(showPanel)))
    menu.addItem(.separator())
    menu.addItem(menuItem("Clear History", #selector(clearHistory)))

    let launchItem = menuItem("Open at Login", #selector(toggleLaunchAtLogin))
    launchAtLoginItem = launchItem
    menu.addItem(launchItem)

    menu.addItem(.separator())
    menu.addItem(menuItem("Quit Clipboard", #selector(quit), key: "q"))

    item.menu = menu
    statusItem = item
  }

  private func menuItem(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
    let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
    item.target = self
    return item
  }

  @objc private func showPanel() {
    bridge?.showPanel()
  }

  @objc private func clearHistory() {
    bridge?.clearHistory()
  }

  @objc private func quit() {
    NSApp.terminate(nil)
  }

  // MARK: - Launch at login

  @objc private func toggleLaunchAtLogin() {
    do {
      if SMAppService.mainApp.status == .enabled {
        try SMAppService.mainApp.unregister()
      } else {
        try SMAppService.mainApp.register()
      }
    } catch {
      // Unsigned builds run from a build directory are often refused here, and
      // a silently unchecked checkbox is worse than an explanation.
      let alert = NSAlert()
      alert.messageText = "Couldn’t change the login item"
      alert.informativeText =
        "\(error.localizedDescription)\n\nThis usually means the app isn’t in /Applications yet."
      alert.runModal()
    }
  }

  // MARK: - Permissions

  /// Prompts on first launch. Auto-paste is a no-op without this, so it is
  /// worth asking for up front rather than at the moment of failure.
  private func promptForAccessibilityIfNeeded() {
    let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    let trusted = AXIsProcessTrustedWithOptions([prompt: true] as CFDictionary)
    if !trusted {
      NSLog("copy_paste: waiting on Accessibility permission for auto-paste")
    }
  }
}

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
  /// Refreshed when the menu opens rather than on a timer.
  func menuWillOpen(_ menu: NSMenu) {
    launchAtLoginItem?.state = SMAppService.mainApp.status == .enabled ? .on : .off
  }
}
