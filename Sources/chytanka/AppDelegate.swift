import AppKit
import Carbon.HIToolbox

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private static let englishVoiceKey = "chytanka.englishWithEnglishVoice"

  private var statusItem: NSStatusItem?
  private var hotKey: HotKey?
  private var englishVoiceItem: NSMenuItem?
  private let speaker = Speaker()

  func applicationDidFinishLaunching(_ notification: Notification) {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    item.button?.image = NSImage(systemSymbolName: "text.bubble", accessibilityDescription: "Chytanka")
    item.menu = makeMenu()
    statusItem = item

    hotKey = HotKey(keyCode: UInt32(kVK_Escape), modifiers: UInt32(controlKey)) { [weak self] in
      self?.toggleReading()
    }
    if hotKey == nil {
      NSLog("chytanka: failed to register the Control-Escape hot key")
    }

    _ = SelectionReader.isTrusted(prompt: true)
  }

  private func makeMenu() -> NSMenu {
    let menu = NSMenu()

    let read = NSMenuItem(title: "Прочитати виділене", action: #selector(readSelection), keyEquivalent: "\u{1b}")
    read.keyEquivalentModifierMask = .control
    read.target = self
    menu.addItem(read)

    let stop = NSMenuItem(title: "Зупинити", action: #selector(stopReading), keyEquivalent: "")
    stop.target = self
    menu.addItem(stop)

    menu.addItem(.separator())

    let english = NSMenuItem(title: "Англійські слова - англійським голосом", action: #selector(toggleEnglishVoice), keyEquivalent: "")
    english.target = self
    english.state = UserDefaults.standard.bool(forKey: Self.englishVoiceKey) ? .on : .off
    menu.addItem(english)
    englishVoiceItem = english

    menu.addItem(.separator())

    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    let about = NSMenuItem(title: "Chytanka \(version)", action: nil, keyEquivalent: "")
    about.isEnabled = false
    menu.addItem(about)

    menu.addItem(NSMenuItem(title: "Вийти", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    return menu
  }

  private func toggleReading() {
    if speaker.isSpeaking {
      speaker.stop()
    } else {
      readSelection()
    }
  }

  @objc private func readSelection() {
    Task { @MainActor in
      guard let text = await SelectionReader.selectedText() else {
        NSSound.beep()
        return
      }
      speaker.speak(text, englishWithEnglishVoice: UserDefaults.standard.bool(forKey: Self.englishVoiceKey))
    }
  }

  @objc private func stopReading() {
    speaker.stop()
  }

  @objc private func toggleEnglishVoice() {
    let enabled = !UserDefaults.standard.bool(forKey: Self.englishVoiceKey)
    UserDefaults.standard.set(enabled, forKey: Self.englishVoiceKey)
    englishVoiceItem?.state = enabled ? .on : .off
  }
}
