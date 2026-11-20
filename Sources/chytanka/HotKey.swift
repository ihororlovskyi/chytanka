import Carbon.HIToolbox

/// Global hot key through Carbon, which needs no Accessibility permission.
final class HotKey {
  private var hotKeyRef: EventHotKeyRef?
  private var handlerRef: EventHandlerRef?
  private let action: @MainActor () -> Void

  init?(keyCode: UInt32, modifiers: UInt32, action: @escaping @MainActor () -> Void) {
    self.action = action

    var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
    let installed = InstallEventHandler(
      GetApplicationEventTarget(),
      { _, _, userData in
        guard let userData else { return noErr }
        let hotKey = Unmanaged<HotKey>.fromOpaque(userData).takeUnretainedValue()
        // Carbon delivers application-target events on the main thread.
        MainActor.assumeIsolated { hotKey.action() }
        return noErr
      },
      1,
      &eventType,
      Unmanaged.passUnretained(self).toOpaque(),
      &handlerRef
    )
    guard installed == noErr else { return nil }

    let hotKeyID = EventHotKeyID(signature: OSType(0x4348_5459), id: 1)
    let registered = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    guard registered == noErr else { return nil }
  }

  deinit {
    if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
    if let handlerRef { RemoveEventHandler(handlerRef) }
  }
}
