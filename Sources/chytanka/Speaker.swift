import AVFoundation
import ChytankaCore

@MainActor
final class Speaker {
  private let synthesizer = AVSpeechSynthesizer()
  private let ukrainianVoice = AVSpeechSynthesisVoice(language: "uk-UA")
  private let englishVoice = AVSpeechSynthesisVoice(language: "en-US")

  var isSpeaking: Bool { synthesizer.isSpeaking }

  func stop() {
    synthesizer.stopSpeaking(at: .immediate)
  }

  func speak(_ text: String, englishWithEnglishVoice: Bool) {
    stop()
    guard englishWithEnglishVoice else {
      enqueue(text, voice: ukrainianVoice)
      return
    }
    for segment in TextSegmenter.segments(of: text) {
      enqueue(segment.text, voice: segment.language == .english ? englishVoice : ukrainianVoice)
    }
  }

  private func enqueue(_ text: String, voice: AVSpeechSynthesisVoice?) {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    let utterance = AVSpeechUtterance(string: trimmed)
    utterance.voice = voice
    synthesizer.speak(utterance)
  }
}
