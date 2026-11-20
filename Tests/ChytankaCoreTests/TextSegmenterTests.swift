import XCTest
@testable import ChytankaCore

final class TextSegmenterTests: XCTestCase {
  func testUkrainianOnlyIsOneSegment() {
    XCTAssertEqual(
      TextSegmenter.segments(of: "Привіт, світе! М'ята 2026."),
      [Segment(text: "Привіт, світе! М'ята 2026.", language: .ukrainian)]
    )
  }

  func testEnglishPhraseInsideUkrainian() {
    XCTAssertEqual(
      TextSegmenter.segments(of: "Відкрий Visual Studio Code, будь ласка"),
      [
        Segment(text: "Відкрий ", language: .ukrainian),
        Segment(text: "Visual Studio Code, ", language: .english),
        Segment(text: "будь ласка", language: .ukrainian),
      ]
    )
  }

  func testLeadingNeutralJoinsFirstRun() {
    XCTAssertEqual(
      TextSegmenter.segments(of: "  42 don't stop"),
      [Segment(text: "  42 don't stop", language: .english)]
    )
  }

  func testEmptyTextHasNoSegments() {
    XCTAssertEqual(TextSegmenter.segments(of: ""), [])
  }

  func testSegmentsJoinBackToInput() {
    let text = "Реліз 0.0.1: додали hotkey та menu bar, далі - ElevenLabs."
    XCTAssertEqual(TextSegmenter.segments(of: text).map(\.text).joined(), text)
  }
}
