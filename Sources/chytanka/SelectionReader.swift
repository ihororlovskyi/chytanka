import AppKit
import ApplicationServices
import Carbon.HIToolbox

/// Reads the selected text of the frontmost app: Accessibility first, then a synthetic Cmd-C
/// for apps that do not expose AXSelectedText (browsers, Electron). Both need Accessibility.
@MainActor
enum SelectionReader {
  static func isTrusted(prompt: Bool) -> Bool {
    let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    return AXIsProcessTrustedWithOptions([key: prompt] as CFDictionary)
  }

  static func selectedText() async -> String? {
    if let text = viaAccessibility() {
      log.notice("selection via accessibility")
      return text
    }
    let text = await viaCopy()
    log.notice("selection via copy: \(text == nil ? "none" : "found", privacy: .public)")
    return text
  }

  private static func viaAccessibility() -> String? {
    let system = AXUIElementCreateSystemWide()
    var focused: CFTypeRef?
    guard AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
          let focused, CFGetTypeID(focused) == AXUIElementGetTypeID() else { return nil }
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(focused as! AXUIElement, kAXSelectedTextAttribute as CFString, &value) == .success,
          let text = value as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
    return text
  }

  private static func viaCopy() async -> String? {
    let pasteboard = NSPasteboard.general
    let saved = pasteboard.pasteboardItems?.map { item in
      item.types.compactMap { type in item.data(forType: type).map { (type, $0) } }
    } ?? []
    let changeCount = pasteboard.changeCount

    postCommandC()
    for _ in 0..<20 where pasteboard.changeCount == changeCount {
      try? await Task.sleep(nanoseconds: 25_000_000)
    }
    guard pasteboard.changeCount != changeCount else { return nil }
    let text = pasteboard.string(forType: .string)

    pasteboard.clearContents()
    pasteboard.writeObjects(saved.map { entries in
      let item = NSPasteboardItem()
      for (type, data) in entries { item.setData(data, forType: type) }
      return item
    })

    guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
    return text
  }

  private static func postCommandC() {
    let source = CGEventSource(stateID: .combinedSessionState)
    for keyDown in [true, false] {
      let event = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: keyDown)
      // Explicit flags drop the Option key the user still holds from the hot key.
      event?.flags = .maskCommand
      event?.post(tap: .cghidEventTap)
    }
  }
}
