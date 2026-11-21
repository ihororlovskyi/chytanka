import XCTest
@testable import ChytankaCore

final class VersionTests: XCTestCase {
  func testComparesComponentsNumerically() {
    XCTAssertTrue(Version.isNewer("0.0.10", than: "0.0.9"))
    XCTAssertTrue(Version.isNewer("0.1", than: "0.0.9"))
    XCTAssertFalse(Version.isNewer("0.0.4", than: "0.0.4"))
    XCTAssertFalse(Version.isNewer("0.0.3", than: "0.0.4"))
  }
}
