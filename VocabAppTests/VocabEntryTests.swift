import XCTest
@testable import VocabApp

final class VocabEntryTests: XCTestCase {
    func testNewEntryIsDueForReview() {
        let entry = VocabEntry(word: "serendipity", language: .en)

        XCTAssertTrue(entry.isDue(on: Date()))
    }

    func testMarkReviewedClearsDueForSameDay() {
        let calendar = Calendar(identifier: .gregorian)
        let reviewedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let sameDay = reviewedAt.addingTimeInterval(60 * 60)
        let nextDay = reviewedAt.addingTimeInterval(60 * 60 * 24)
        let entry = VocabEntry(word: "serendipity", language: .en)

        entry.markReviewed(at: reviewedAt)

        XCTAssertEqual(entry.reviewCount, 1)
        XCTAssertFalse(entry.isDue(on: sameDay, calendar: calendar))
        XCTAssertTrue(entry.isDue(on: nextDay, calendar: calendar))
    }

    func testEasyReviewSchedulesLongerInterval() {
        let calendar = Calendar(identifier: .gregorian)
        let reviewedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let entry = VocabEntry(word: "serendipity", language: .en)

        entry.markReviewed(quality: .easy, at: reviewedAt, calendar: calendar)

        XCTAssertEqual(entry.reviewIntervalDays, 3)
        XCTAssertEqual(entry.easeFactor, 2.65, accuracy: 0.001)
        XCTAssertFalse(entry.isDue(on: reviewedAt.addingTimeInterval(60 * 60 * 24), calendar: calendar))
        XCTAssertTrue(entry.isDue(on: reviewedAt.addingTimeInterval(60 * 60 * 24 * 3), calendar: calendar))
    }

    func testClozeSentenceBlanksWord() {
        let entry = VocabEntry(
            word: "serendipity",
            language: .en,
            sentence: "Serendipity helped her find the right book."
        )

        XCTAssertEqual(entry.clozeSentence, "_____ helped her find the right book.")
    }
}
