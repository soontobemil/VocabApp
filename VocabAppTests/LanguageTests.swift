import XCTest
@testable import VocabApp

final class LanguageTests: XCTestCase {
    func testEnglishWordDetectsEnglish() {
        XCTAssertEqual(Language.detect(from: "serendipity"), .en)
    }

    func testKoreanWordDetectsKorean() {
        XCTAssertEqual(Language.detect(from: "사과"), .ko)
    }

    func testMixedStartingWithEnglishContainingHangulIsKorean() {
        XCTAssertEqual(Language.detect(from: "apple 사과"), .ko)
    }

    func testJamoDetectsKorean() {
        XCTAssertEqual(Language.detect(from: "ㄱㄴㄷ"), .ko)
    }

    func testEmptyStringDefaultsToEnglish() {
        XCTAssertEqual(Language.detect(from: ""), .en)
    }

    func testNumbersAndPunctuationDefaultToEnglish() {
        XCTAssertEqual(Language.detect(from: "123 !?"), .en)
    }
}
