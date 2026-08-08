import ApplicationServices
import Carbon.HIToolbox
import Cocoa
import FlutterMacOS

/// Kol 7aga betlamis macOS mawgooda hena: motab3et el clipboard, eznhar w
/// ekhfa2 el panel, w 3amal el paste nafso.
///
/// El taqseem basit: el Swift mas2ool 3an el system, w el Dart mas2ool 3an
/// el list w el shakl bas.
final class ClipboardBridge {
  private let channel: FlutterMethodChannel
  private let pasteboard = NSPasteboard.general
  private weak var window: MainFlutterWindow?

  private var lastChangeCount: Int
  private var timer: Timer?
  private var resignObserver: NSObjectProtocol?
  private var activateObserver: NSObjectProtocol?

  /// El app elly kan 2oddam 2abl ma el panel yeftah, 3ashan el paste yerga3
  /// yenzel fel makan elly el user kan feeh fe3lan.
  ///
  /// Strong mesh weak — w di kanet EL bug. El NSRunningApplication elly
  /// betegi fel notification mafeesh 7ad tani mesekha, fa lama kanet weak
  /// kanet betmoot fawran, w wa2t el paste kona bnel2eeha nil — fa el ⌘V
  /// makansh beyetba3at aslan (aw kan beyenzel 3ala app-na e7na: el beep).
  private var previousApp: NSRunningApplication?

  /// Nafs el 7ala elly 2olnaha lel Dart. Lama el panel yekoon ma5fi e7na
  /// bene-sheel kol el UI 3ashan mafeesh 7aga tefdal betet7arrak fel khalfeya.
  private var panelVisible = false

  /// El wa2t elly bnestanah ba3d ma nerga3 el focus lel app el tanya.
  /// Lazem yekoon fih delay 3ashan targee3 el focus mesh bey7sal fawran.
  private static let pasteDelay: TimeInterval = 0.08

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

    // Bene-tabe3 akher app etfata7et 8erena 3ala tool, badal ma nes2al bas fe
    // lah7zet ma el panel yeftah. Fel lah7za di e7na momken nekoon e7na
    // el 2oddam khalas (mesalan lama tefta7 min el menu bar aw min el Finder),
    // w saa3etha kona bene-seeb `previousApp` fadya w el paste maye7salsh.
    activateObserver = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didActivateApplicationNotification,
      object: nil, queue: .main
    ) { [weak self] note in
      guard
        let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
        app.bundleIdentifier != Bundle.main.bundleIdentifier
      else { return }
      self?.previousApp = app
    }

    // `hidesOnDeactivate` bey2fel el panel min wara dahrena lama el user
    // yedous barra, fa di el tare2a el wa7eda enena ne3raf el 7ala di.
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
    if let activateObserver {
      NSWorkspace.shared.notificationCenter.removeObserver(activateObserver)
    }
  }

  // MARK: - Elte2at el clipboard

  /// macOS mafihoosh notification lama el clipboard yetghayyar — moqarnet
  /// `changeCount` heya el tare2a el wa7eda el mawgooda, 3ashan keda di el
  /// mkan el wa7eed elly bne3mel feeh polling fel app kolaha.
  ///
  /// 2era2et raqam wa7ed marritin fel sanya haga mesh mo2assera khales.
  /// El mohim howa el `tolerance`: bey5alli el kernel yegma3 el sa3a di ma3a
  /// sa3at tanya badal ma ye-sa77i el CPU la wa7do.
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

  // MARK: - El panel

  func showPanel() {
    guard let window else { return }

    // `previousApp` bey-etzabbat lewa7do min el observer fo2.

    // Bene2ol lel Dart el awwil 3ashan yeb2a 5alas 3amel build lel list 2abl
    // ma el window teban 3ala el shasha.
    setPanelVisible(true)
    window.positionOnActiveScreen()
    // Ba3d `NSApp.hide` fe amaleyet el paste el app betfdal fe 7alet "hidden",
    // fa lazem nefokoha el awwil.
    NSApp.unhide(nil)
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

  // MARK: - El paste

  /// El tarteeb hena mohim geddan. Law 3amaltoh ghalat el paste hayenzel fe
  /// app tanya, aw mesh hayenzel khales.
  private func paste(_ text: String) {
    // 1) 7ot el text 3ala el clipboard.
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
    // 2) Sagil el raqam el gedeed 3ashan el kitaba bta3etna e7na materga3sh
    //    tani ka 7aga gedida fel history.
    lastChangeCount = pasteboard.changeCount

    // 3) 2fel el panel. `NSApp.hide` mesh bas `orderOut`: el orderOut bey5abbi
    //    el window bas w app-na yefdal howa el active, fa el ⌘V yenzel 3andena
    //    e7na w el nizam ye3mel beep 3ashan mafeesh 7ad 3ando 7aga yelza2ha.
    //    El hide howa elly bey-sallem el focus lel app elly wara-na sa7.
    window?.orderOut(nil)
    setPanelVisible(false)
    NSApp.hide(nil)

    // 4) Man8ir el Accessibility el CGEvent bey-fshal fe sokoot tam, w el user
    //    beyshoof en el app bazet min gher sabab. Fa a7san 7aga ne2oolo.
    //    El text bardo lessa 3ala el clipboard, fa momken ye3mel ⌘V be2edo.
    guard AXIsProcessTrusted() else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
        self?.warnAboutAccessibility()
      }
      return
    }

    guard let target = previousApp else {
      NSLog("copy_paste: mafeesh previousApp — el text 3ala el clipboard bas")
      return
    }

    // 5) Estanna le7ad ma el app el tanya teb2a active fe3lan, ba3dein ab3at.
    _ = target.activate(options: [])
    waitForFocusThenPaste(target, attempt: 0)
  }

  /// Delay sabet howa takhmeen: momken yekoon 2osayyar fa el ⌘V yerou7 fel
  /// hawa, w momken yekoon taweel fa el 7aga tebayyaz bati2a. Fa badal keda
  /// bene-tabe3 le7ad ma el app el matlouba teb2a heya el active.
  private func waitForFocusThenPaste(_ target: NSRunningApplication, attempt: Int) {
    let maxAttempts = 20  // 20 × 50ms = sanya wa7da 3ala el akter

    if !target.isActive && attempt < maxAttempts {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
        self?.waitForFocusThenPaste(target, attempt: attempt + 1)
      }
      return
    }

    let front = NSWorkspace.shared.frontmostApplication?.localizedName ?? "?"
    NSLog(
      "copy_paste: ⌘V -> \(target.localizedName ?? "?") | active=\(target.isActive) "
        + "| frontmost=\(front) | mo7awlat=\(attempt)")

    // Shwayet wa2t kaman ba3d ma yeb2a active, 3ashan el text field gowah
    // yekoon khad el focus howa kaman.
    DispatchQueue.main.asyncAfter(deadline: .now() + Self.pasteDelay) {
      Self.sendCommandV()
    }
  }

  private static func sendCommandV() {
    // `.privateState` mesh bey-warras 7alet el azrar el mad8oota dilwa2ti.
    // Law estakhdemna el 7ala el 3adeya w el user lessa masek ⌘⇧ min el
    // shortcut, el event hayetla3 ⌘⇧V mesh ⌘V — w da mesh paste fe mo3zam
    // el apps.
    let source = CGEventSource(stateID: .privateState)
    let v = CGKeyCode(kVK_ANSI_V)
    guard let down = CGEvent(keyboardEventSource: source, virtualKey: v, keyDown: true),
      let up = CGEvent(keyboardEventSource: source, virtualKey: v, keyDown: false)
    else { return }

    down.flags = .maskCommand
    up.flags = .maskCommand
    // `.cghidEventTap` bey-do5ol el event min awwil el tareeq, fa kol el apps
    // beteshoofo 3ala 3aks el taps el tanya.
    down.post(tap: .cghidEventTap)
    up.post(tap: .cghidEventTap)
  }

  /// Betban lama el paste yefshal 3ashan el Accessibility mesh mafto7a.
  private func warnAboutAccessibility() {
    activateSelf()

    let alert = NSAlert()
    alert.messageText = "2as w Laze2 can’t paste for you yet"
    alert.informativeText = """
      Pasting into other apps needs the Accessibility permission.

      Your item is already on the clipboard, so you can press ⌘V yourself in \
      the meantime.
      """
    alert.addButton(withTitle: "Open Settings")
    alert.addButton(withTitle: "Not Now")

    if alert.runModal() == .alertFirstButtonReturn,
      let url = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    {
      NSWorkspace.shared.open(url)
    }
  }

  private func activateSelf() {
    if #available(macOS 14.0, *) {
      NSApp.activate()
    } else {
      NSApp.activate(ignoringOtherApps: true)
    }
  }
}
