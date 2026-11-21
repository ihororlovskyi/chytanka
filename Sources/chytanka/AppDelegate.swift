import AppKit
import Carbon.HIToolbox
import OSLog

let log = Logger(subsystem: "com.ihororlovskyi.chytanka", category: "app")

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

    let trusted = SelectionReader.isTrusted(prompt: true)
    log.notice("launched, accessibility trusted: \(trusted)")
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
    guard SelectionReader.isTrusted(prompt: false) else {
      log.error("read requested without accessibility permission")
      showAccessibilityAlert()
      return
    }
    Task { @MainActor in
      guard let text = await SelectionReader.selectedText() else {
        log.notice("no selected text found")
        NSSound.beep()
        return
      }
      log.notice("speaking \(text.count) characters")
      speaker.speak(text, englishWithEnglishVoice: UserDefaults.standard.bool(forKey: Self.englishVoiceKey))
    }
  }

  private func showAccessibilityAlert() {
    NSApp.activate(ignoringOtherApps: true)
    let alert = NSAlert()
    alert.messageText = "Chytanka потребує дозволу Accessibility"
    alert.informativeText = "Без нього застосунок не бачить виділений текст. Увімкніть Chytanka в System Settings → Privacy & Security → Accessibility. Якщо запис уже увімкнений, видаліть його кнопкою «−» і додайте застосунок знову."
    alert.addButton(withTitle: "Відкрити налаштування")
    alert.addButton(withTitle: "Скасувати")
    if alert.runModal() == .alertFirstButtonReturn,
       let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
      NSWorkspace.shared.open(url)
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
