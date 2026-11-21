import AppKit
import Carbon.HIToolbox
import OSLog
import ServiceManagement

let log = Logger(subsystem: "com.ihororlovskyi.chytanka", category: "app")

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
  private static let voiceKey = "chytanka.voice"
  private static let repositoryURL = URL(string: "https://github.com/ihororlovskyi/chytanka")!

  private var statusItem: NSStatusItem?
  private var hotKey: HotKey?
  private let voiceMenu = NSMenu()
  private let loginItemMenuItem = NSMenuItem(title: String(localized: "Launch at Login"), action: nil, keyEquivalent: "")
  private let speaker = Speaker()
  private let updater = Updater()
  private let updateMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")

  func applicationDidFinishLaunching(_ notification: Notification) {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    item.button?.image = NSImage(systemSymbolName: "text.bubble", accessibilityDescription: "Chytanka")
    item.menu = makeMenu()
    statusItem = item
    speaker.loadDictionary()
    updater.onChange = { [weak self] in self?.refreshUpdateItem() }
    updater.start()

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

    let read = NSMenuItem(title: String(localized: "Read Selection"), action: #selector(readSelection), keyEquivalent: "\u{1b}")
    read.keyEquivalentModifierMask = .control
    read.target = self
    menu.addItem(read)

    let stop = NSMenuItem(title: String(localized: "Stop"), action: #selector(stopReading), keyEquivalent: "")
    stop.target = self
    menu.addItem(stop)

    menu.addItem(.separator())

    let voice = NSMenuItem(title: String(localized: "Voice"), action: nil, keyEquivalent: "")
    voice.submenu = voiceMenu
    menu.addItem(voice)

    menu.delegate = self

    menu.addItem(.separator())

    updateMenuItem.target = self
    updateMenuItem.action = #selector(installUpdate)
    updateMenuItem.isHidden = true
    menu.addItem(updateMenuItem)

    loginItemMenuItem.target = self
    loginItemMenuItem.action = #selector(toggleLaunchAtLogin)
    menu.addItem(loginItemMenuItem)

    let about = NSMenuItem(title: String(localized: "About Chytanka"), action: #selector(showAbout), keyEquivalent: "")
    about.target = self
    menu.addItem(about)

    menu.addItem(.separator())

    menu.addItem(NSMenuItem(title: String(localized: "Quit Chytanka"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
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
      speaker.speak(text, voiceIdentifier: UserDefaults.standard.string(forKey: Self.voiceKey))
    }
  }

  private func showAccessibilityAlert() {
    NSApp.activate(ignoringOtherApps: true)
    let alert = NSAlert()
    alert.messageText = String(localized: "Chytanka needs Accessibility permission")
    alert.informativeText = String(localized: "Without it the app cannot see the selected text. Turn on Chytanka in System Settings → Privacy & Security → Accessibility. If it is already on, remove it with the “−” button and add the app again.")
    alert.addButton(withTitle: String(localized: "Open Settings"))
    alert.addButton(withTitle: String(localized: "Cancel"))
    if alert.runModal() == .alertFirstButtonReturn,
       let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
      NSWorkspace.shared.open(url)
    }
  }

  @objc private func stopReading() {
    speaker.stop()
  }

  // Rebuilt on every open, so a voice downloaded in System Settings shows up without a restart.
  func menuNeedsUpdate(_ menu: NSMenu) {
    voiceMenu.removeAllItems()
    let voices = Speaker.ukrainianVoices()
    let selected = UserDefaults.standard.string(forKey: Self.voiceKey)
    let active = voices.first { $0.identifier == selected } ?? voices.first
    for voice in voices {
      let item = NSMenuItem(title: Speaker.title(of: voice), action: #selector(selectVoice(_:)), keyEquivalent: "")
      item.target = self
      item.representedObject = voice.identifier
      item.state = voice.identifier == active?.identifier ? .on : .off
      voiceMenu.addItem(item)
    }
    if voices.isEmpty {
      let none = NSMenuItem(title: String(localized: "No Ukrainian voice installed"), action: nil, keyEquivalent: "")
      none.isEnabled = false
      voiceMenu.addItem(none)
    }

    refreshLoginItem()
  }

  @objc private func selectVoice(_ sender: NSMenuItem) {
    UserDefaults.standard.set(sender.representedObject as? String, forKey: Self.voiceKey)
  }

  private func refreshUpdateItem() {
    guard let version = updater.availableVersion else {
      updateMenuItem.isHidden = true
      return
    }
    updateMenuItem.title = String(format: String(localized: "Download and Install %@"), version)
    updateMenuItem.isHidden = false
  }

  @objc private func installUpdate() {
    updater.install()
  }

  private func refreshLoginItem() {
    switch SMAppService.mainApp.status {
    case .enabled:
      loginItemMenuItem.title = String(localized: "Launch at Login")
      loginItemMenuItem.state = .on
    case .requiresApproval:
      loginItemMenuItem.title = String(localized: "Launch at Login - Approval Required")
      loginItemMenuItem.state = .mixed
    default:
      loginItemMenuItem.title = String(localized: "Launch at Login")
      loginItemMenuItem.state = .off
    }
  }

  @objc private func toggleLaunchAtLogin() {
    let service = SMAppService.mainApp
    // Registered but unapproved: only System Settings can approve it.
    if service.status == .requiresApproval {
      SMAppService.openSystemSettingsLoginItems()
      return
    }
    do {
      if service.status == .enabled {
        try service.unregister()
      } else {
        try service.register()
      }
    } catch {
      log.error("login item change failed: \(error.localizedDescription, privacy: .public)")
      NSApp.activate(ignoringOtherApps: true)
      let alert = NSAlert()
      alert.messageText = String(localized: "Could not change the login item")
      alert.informativeText = error.localizedDescription + "\n\n" + String(localized: "Registration usually fails when the app runs from outside /Applications. Move Chytanka.app to /Applications and try again.")
      alert.alertStyle = .warning
      alert.runModal()
    }
    refreshLoginItem()
  }

  @objc private func showAbout() {
    // LSUIElement apps are not active by default; without this the panel opens behind other windows.
    NSApp.activate(ignoringOtherApps: true)
    let font = NSFont.systemFont(ofSize: 11)
    let credits = NSMutableAttributedString(string: String(localized: "Pronunciations: CMU Pronouncing Dictionary") + "\n", attributes: [.font: font])
    credits.append(NSAttributedString(string: "GitHub", attributes: [.font: font, .link: Self.repositoryURL]))
    NSApplication.shared.orderFrontStandardAboutPanel(options: [.applicationName: "Chytanka", .credits: credits])
  }
}
