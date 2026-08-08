import Cocoa
import FlutterMacOS

/// The popup panel.
///
/// Configured once at launch and then only ordered in and out, never closed, so
/// the Flutter engine stays warm and summoning the panel is instant.
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
    // .titled rather than .borderless: rounded corners, the window shadow, and
    // the ability to become key all come for free instead of being overridden.
    styleMask = [.titled, .fullSizeContentView]
    titlebarAppearsTransparent = true
    titleVisibility = .hidden
    standardWindowButton(.closeButton)?.isHidden = true
    standardWindowButton(.miniaturizeButton)?.isHidden = true
    standardWindowButton(.zoomButton)?.isHidden = true
    isMovableByWindowBackground = false

    level = .floating
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    // Clicking anywhere else dismisses the panel. No global click monitor.
    hidesOnDeactivate = true
    isReleasedWhenClosed = false

    setContentSize(Self.panelSize)
    orderOut(nil)
  }

  /// Spotlight-style placement: horizontally centred on whichever screen holds
  /// the pointer, a fifth of the way down.
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
