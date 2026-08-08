import Cocoa
import FlutterMacOS

/// El panel el soghayar elly beyeftah bel shortcut.
///
/// Bene-zabbato marra wa7da fel bedaya, w ba3d keda bene-tal3o w nenazzelo bas,
/// 3omro ma bye2fel — 3ashan el Flutter engine yefdal shaghal w el panel yeftah
/// fel 7al.
class MainFlutterWindow: NSWindow {
  static let panelSize = NSSize(width: 560, height: 360)

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    contentViewController = flutterViewController
    RegisterGeneratedPlugins(registry: flutterViewController)
    configureAsPanel()
    super.awakeFromNib()
  }

  private func configureAsPanel() {
    // E5tarna `.titled` mesh `.borderless`: kida el zawaya el medawwara w el
    // dell w emkaneyet en el window teb2a key beygo ma3ana be balash badal ma
    // ne3melhom kollohom be2edena.
    styleMask = [.titled, .fullSizeContentView]
    titlebarAppearsTransparent = true
    titleVisibility = .hidden
    standardWindowButton(.closeButton)?.isHidden = true
    standardWindowButton(.miniaturizeButton)?.isHidden = true
    standardWindowButton(.zoomButton)?.isHidden = true
    isMovableByWindowBackground = false

    level = .floating
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    // Ay dosa barra el panel bet2felo. Min gher ma nektib wala satr zeyada.
    hidesOnDeactivate = true
    isReleasedWhenClosed = false

    setContentSize(Self.panelSize)
    orderOut(nil)
  }

  /// Nafs fekret el Spotlight: fel nos min barra w khomus el shasha min fo2,
  /// 3ala el shasha elly el mouse mawgood feeha.
  func positionOnActiveScreen() {
    let mouse = NSEvent.mouseLocation
    let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
    guard let visible = screen?.visibleFrame else { return }
    let size = frame.size
    let x = visible.midX - size.width / 2
    let y = visible.maxY - visible.height * 0.2 - size.height
    setFrameOrigin(NSPoint(x: x.rounded(), y: y.rounded()))
  }

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }
}
