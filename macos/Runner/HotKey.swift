import Carbon.HIToolbox

/// A thin wrapper over Carbon's `RegisterEventHotKey`.
///
/// This is still the only way to get a system-wide shortcut that does *not*
/// require the Accessibility permission, so the hotkey works even before the
/// user has granted anything. It is also genuinely event-driven: the kernel
/// delivers the event, nothing is polled.
///
/// The API is long deprecated in the sense that Carbon is, but it remains
/// functional and every alternative (a global NSEvent monitor, an event tap)
/// costs an Accessibility grant for strictly less reliability.
final class HotKey {
  private var hotKeyRef: EventHotKeyRef?
  private var eventHandler: EventHandlerRef?
  private let action: () -> Void

  init?(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
    self.action = action

    var spec = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard),
      eventKind: UInt32(kEventHotKeyPressed))

    // The C callback cannot capture context, so the instance is passed through
    // userData instead.
    let context = Unmanaged.passUnretained(self).toOpaque()
    let installed = InstallEventHandler(
      GetApplicationEventTarget(),
      { _, _, userData in
        guard let userData else { return noErr }
        Unmanaged<HotKey>.fromOpaque(userData).takeUnretainedValue().action()
        return noErr
      },
      1, &spec, context, &eventHandler)
    guard installed == noErr else { return nil }

    let id = EventHotKeyID(signature: OSType(0x434C_4950), id: 1)  // 'CLIP'
    let registered = RegisterEventHotKey(
      keyCode, modifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef)
    guard registered == noErr else { return nil }
  }

  deinit {
    if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
    if let eventHandler { RemoveEventHandler(eventHandler) }
  }
}
