import XCTest
@testable import ChytankaCore

final class TransliteratorTests: XCTestCase {
  private let transliterator = Transliterator(pronunciations: [
    "git": "G IH1 T",
    "push": "P UH1 SH",
    "computer": "K AH0 M P Y UW1 T ER0",
    "code": "K OW1 D",
    "apple": "AE1 P AH0 L",
    "studio": "S T UW1 D IY0 OW2",
    "start": "S T AA1 R T",
    "docker": "D AA1 K ER0",
    "mac": "M AE1 K",
    "book": "B UH1 K",
    "youtube": "Y UW1 T Y UW2 B",
    "commit": "K AH0 M IH1 T",
    "terminal": "T ER1 M AH0 N AH0 L",
    "product": "P R AA1 D AH0 K T",
  ])

  func testParsesCMUDictSkippingAlternatesAndComments() {
    let parsed = Transliterator.parseCMUDict("""
    code K OW1 D
    code(2) K AH0 D
    aalen AE1 L AH0 N # place, german
    """)
    XCTAssertEqual(parsed, ["code": "K OW1 D", "aalen": "AE1 L AH0 N"])
  }

  func testWordsFromPronunciations() {
    XCTAssertEqual(transliterator.word("push"), "пуш")
    XCTAssertEqual(transliterator.word("Code"), "Коуд")
    XCTAssertEqual(transliterator.word("apple"), "епл")
    XCTAssertEqual(transliterator.word("Studio"), "Студіо")
    XCTAssertEqual(transliterator.word("start"), "старт")
    XCTAssertEqual(transliterator.word("Docker"), "Докер")
  }

  func testReducedVowelFollowsSpelling() {
    XCTAssertEqual(transliterator.word("commit"), "коміт")
    XCTAssertEqual(transliterator.word("computer"), "компʼютер")
    XCTAssertEqual(transliterator.word("Terminal"), "Термінал")
    XCTAssertEqual(transliterator.word("product"), "продакт")
  }

  func testOverridesWinOverPronunciations() {
    XCTAssertEqual(transliterator.word("YouTube"), "Ютуб")
  }

  func testShortAcronymsAreSpelled() {
    XCTAssertEqual(transliterator.word("API"), "Ей пі ай")
  }

  func testCamelCaseJoinsParts() {
    XCTAssertEqual(transliterator.word("MacBook"), "Мекбук")
  }

  func testUnknownWordFallsBackToSpelling() {
    XCTAssertEqual(transliterator.word("zork"), "зорк")
    XCTAssertEqual(transliterator.word("quick"), "квік")
  }

  func testReplacesOnlyLatinWords() {
    XCTAssertEqual(
      transliterator.transliterate(text: "Зроби git push, будь ласка: 2 рази."),
      "Зроби ґіт пуш, будь ласка: 2 рази."
    )
  }
}
