import Carbon.HIToolbox

/// Ghelaf ba3eet 7awalin `RegisterEventHotKey` bta3 Carbon.
///
/// Lessa di el tare2a el wa7eda 3ashan tegeeb shortcut sha8al 3ala mostawa el
/// nizam kollo min gher ma te7tag Accessibility — ya3ni el shortcut beyeshtaghal
/// 7atta 2abl ma el user yedeek ay ezn. W kaman howa event 7a2i2i: el kernel
/// howa elly beyeb3atlak el 7adas, mafeesh 7aga bete-check fe halaqa.
///
/// Carbon 2adeem aywa, bas lessa shaghal, w kol el badayel (global NSEvent
/// monitor aw event tap) hatetkallefak ezn Accessibility mo2abel dama2 a2al.
final class HotKey {
  private var hotKeyRef: EventHotKeyRef?
  private var eventHandler: EventHandlerRef?
  private let action: () -> Void

  init?(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
    self.action = action

    var spec = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard),
      eventKind: UInt32(kEventHotKeyPressed))

    // El callback bta3 el C mesh momken ye-shil ay context gowah, 3ashan keda
    // bene3addi el object nafso min khilal userData.
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
