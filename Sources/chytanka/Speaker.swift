import AVFoundation
import ChytankaCore

@MainActor
final class Speaker {
  private let synthesizer = AVSpeechSynthesizer()
  /// Starts without pronunciations; the full dictionary arrives from `loadDictionary()`.
  private var transliterator = Transliterator(pronunciations: [:])

  var isSpeaking: Bool { synthesizer.isSpeaking }

  /// Installed Ukrainian voices, best quality first (Enhanced before the compact Lesya).
  static func ukrainianVoices() -> [AVSpeechSynthesisVoice] {
    AVSpeechSynthesisVoice.speechVoices()
      .filter { $0.language == "uk-UA" }
      .sorted { $0.quality.rawValue > $1.quality.rawValue }
  }

  static func title(of voice: AVSpeechSynthesisVoice) -> String {
    switch voice.quality {
    case .premium: return "\(voice.name) (Premium)"
    case .enhanced: return "\(voice.name) (Enhanced)"
    default: return voice.name
    }
  }

  func loadDictionary() {
    guard let url = Bundle.main.url(forResource: "cmudict", withExtension: "dict") else {
      log.error("cmudict.dict is missing from the app bundle")
      return
    }
    Task.detached(priority: .utility) {
      guard let text = try? String(contentsOf: url, encoding: .utf8) else { return }
      let pronunciations = Transliterator.parseCMUDict(text)
      await MainActor.run {
        self.transliterator = Transliterator(pronunciations: pronunciations)
        log.notice("loaded \(pronunciations.count) pronunciations")
      }
    }
  }

  func stop() {
    synthesizer.stopSpeaking(at: .immediate)
  }

  func speak(_ text: String, voiceIdentifier: String?) {
    stop()
    let voices = Self.ukrainianVoices()
    let ukrainianVoice = voices.first { $0.identifier == voiceIdentifier } ?? voices.first
    enqueue(transliterator.transliterate(text: text), voice: ukrainianVoice)
  }

  private func enqueue(_ text: String, voice: AVSpeechSynthesisVoice?) {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    let utterance = AVSpeechUtterance(string: trimmed)
    utterance.voice = voice
    synthesizer.speak(utterance)
  }
}
