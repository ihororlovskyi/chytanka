import AppKit
import ChytankaCore

/// Checks GitHub for a newer release and installs it with the bundled install.sh,
/// or with Homebrew when the cask manages the app.
@MainActor
final class Updater {
  private static let latestReleaseURL = URL(string: "https://api.github.com/repos/ihororlovskyi/chytanka/releases/latest")!
  private static let caskrooms = ["/opt/homebrew/Caskroom/chytanka", "/usr/local/Caskroom/chytanka"]

  private(set) var availableVersion: String?
  var onChange: (() -> Void)?
  private var timer: Timer?

  static var currentVersion: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
  }

  func start() {
    check()
    timer = Timer.scheduledTimer(withTimeInterval: 6 * 60 * 60, repeats: true) { _ in
      MainActor.assumeIsolated { self.check() }
    }
  }

  func check() {
    Task {
      do {
        let (data, _) = try await URLSession.shared.data(from: Self.latestReleaseURL)
        struct Release: Decodable { let tag_name: String }
        let latest = try JSONDecoder().decode(Release.self, from: data).tag_name
        availableVersion = Version.isNewer(latest, than: Self.currentVersion) ? latest : nil
        log.notice("latest release \(latest, privacy: .public), installed \(Self.currentVersion, privacy: .public)")
        onChange?()
      } catch {
        log.error("update check failed: \(error.localizedDescription, privacy: .public)")
      }
    }
  }

  /// Runs the installer as a separate process: it quits this app, replaces it, and opens the new one.
  func install() {
    guard let version = availableVersion else { return }
    let command: String
    if Self.caskrooms.contains(where: { FileManager.default.fileExists(atPath: $0) }) {
      let brew = FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew") ? "/opt/homebrew/bin/brew" : "/usr/local/bin/brew"
      command = "\(brew) upgrade --cask chytanka && open /Applications/Chytanka.app"
    } else {
      guard let script = Bundle.main.url(forResource: "install", withExtension: "sh") else {
        log.error("install.sh is missing from the app bundle")
        return
      }
      // A copy outside the bundle, since the installer deletes the bundle it runs from.
      let copy = FileManager.default.temporaryDirectory.appendingPathComponent("chytanka-install.sh")
      try? FileManager.default.removeItem(at: copy)
      try? FileManager.default.copyItem(at: script, to: copy)
      command = "/bin/sh '\(copy.path)' install '\(version)'"
    }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/sh")
    process.arguments = ["-c", "\(command) >/tmp/chytanka-update.log 2>&1"]
    do {
      try process.run()
      log.notice("installing \(version, privacy: .public)")
    } catch {
      log.error("update failed to start: \(error.localizedDescription, privacy: .public)")
      NSSound.beep()
    }
  }
}
