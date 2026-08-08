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
    // Law fih nosha tanya min el app shaghala 5alas, e2fel nafsak w sahheeha.
    //
    // Min gher el 7etta di momken teb2a shaghal nos5tein — wa7da min folder
    // el build w wa7da min /Applications — w saa3etha:
    //   - wa7da bas heya elly hateakhod el ⌘⇧V (el tanya el tasgeel beta3ha
    //     beye-fshal fe sokoot),
    //   - w el ezn bta3 el Accessibility motrabet bel masar, ya3ni momken
    //     te-eddi el ezn le wa7da w el tanya heya elly shaghala fe3lan.
    // W keda te2rab teganen 3ashan kol 7aga shakloha mazbota.
    if terminateIfAlreadyRunning() { return }

    guard let window = mainFlutterWindow as? MainFlutterWindow,
      let controller = window.contentViewController as? FlutterViewController
    else {
      NSLog("copy_paste: mafeesh Flutter window nerbot 3aleha")
      return
    }

    bridge = ClipboardBridge(
      messenger: controller.engine.binaryMessenger, window: window)

    // Beyebda2 ma5fi — el panel bene-nadeeh, mesh beyeftah lewa7do.
    window.orderOut(nil)

    setUpStatusItem()

    hotKey = HotKey(
      keyCode: UInt32(kVK_ANSI_V),
      modifiers: UInt32(cmdKey | shiftKey)
    ) { [weak self] in
      dlog("hotkey ⌘⇧V etdas")
      self?.bridge?.togglePanel()
    }
    if hotKey == nil {
      NSLog("copy_paste: ⌘⇧V ma7goz le 7ad tani; estakhdem el menu bar")
    }

    promptForAccessibilityIfNeeded()
  }

  private func terminateIfAlreadyRunning() -> Bool {
    guard let bundleID = Bundle.main.bundleIdentifier else { return false }
    let me = ProcessInfo.processInfo.processIdentifier
    let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
      .filter { $0.processIdentifier != me }
    guard let existing = others.first else { return false }

    NSLog("copy_paste: fih nosha shaghala 5alas (pid \(existing.processIdentifier)) — 2afel nafsi")
    _ = existing.activate(options: [])
    NSApp.terminate(nil)
    return true
  }

  /// E2fal el panel mayenfa3sh yeqfel app shaghala fel khalfeya.
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  /// Law fata7t app shaghala 5alas min el Finder, el 3ady enno mayeb2ash fih
  /// ay rad fe3l — w da beyballagh el user en el app bazet.
  override func applicationShouldHandleReopen(
    _ sender: NSApplication, hasVisibleWindows flag: Bool
  ) -> Bool {
    bridge?.showPanel()
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // MARK: - El menu bar

  /// Ma3a `LSUIElement` mafeesh ayqona fel Dock wala menu lel app, fa min gher
  /// el 7aga di el user mesh hayel2a tare2a ye2fel beeha el app aslan.
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
    // Lazem ne7add el target be nafsena, 8er keda el menu hayedawwar fel
    // responder chain w mesh haylae2 7ad yerod.
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

  // MARK: - El fat7 ma3a el tashgheel

  @objc private func toggleLaunchAtLogin() {
    do {
      if SMAppService.mainApp.status == .enabled {
        try SMAppService.mainApp.unregister()
      } else {
        try SMAppService.mainApp.register()
      }
    } catch {
      // El nosakh el 8er mowaqqa3a w el shaghala min folder el build kiteer
      // beyetrafedo hena, w 3alama mesh betetzabbat min gher tafseer a7'las
      // min en el user yefdal yesa2al.
      let alert = NSAlert()
      alert.messageText = "Couldn’t change the login item"
      alert.informativeText =
        "\(error.localizedDescription)\n\nThis usually means the app isn’t in /Applications yet."
      alert.runModal()
    }
  }

  // MARK: - El azoonat

  /// Beyes2al awwil marra bas. El paste el otomatiki mayeshtaghalsh khales min
  /// gher el ezn da, fa a7san nes2al min el bedaya mesh fe lah7zet el fashal.
  private func promptForAccessibilityIfNeeded() {
    let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    let trusted = AXIsProcessTrustedWithOptions([prompt: true] as CFDictionary)
    if !trusted {
      NSLog("copy_paste: mestanyeen ezn el Accessibility 3ashan el paste")
    }
  }
}

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
  /// Bene7addes el 3alama lama el menu yeftah, mesh 3ala sa3a bete-shtaghal
  /// tool el wa2t.
  func menuWillOpen(_ menu: NSMenu) {
    launchAtLoginItem?.state = SMAppService.mainApp.status == .enabled ? .on : .off
  }
}
