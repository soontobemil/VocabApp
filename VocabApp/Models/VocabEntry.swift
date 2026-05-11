import Foundation
import SwiftData

@Model
final class VocabEntry {
    var id: UUID = UUID()
    var word: String = ""
    var languageRaw: String = Language.en.rawValue
    var definition: String?
    var translation: String?
    var sentence: String?
    var bookTitle: String?
    var createdAt: Date = Date()
    var isFavorite: Bool = false
    var lastReviewedAt: Date?
    var reviewCount: Int = 0

    var language: Language {
        get { Language(rawValue: languageRaw) ?? .en }
        set { languageRaw = newValue.rawValue }
    }

    func isDue(on date: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard let lastReviewedAt else { return true }
        return !calendar.isDate(lastReviewedAt, inSameDayAs: date)
    }

    func markReviewed(at date: Date = Date()) {
        lastReviewedAt = date
        reviewCount += 1
    }

    init(
        word: String,
        language: Language,
        definition: String? = nil,
        translation: String? = nil,
        sentence: String? = nil,
        bookTitle: String? = nil,
        createdAt: Date = Date(),
        isFavorite: Bool = false,
        lastReviewedAt: Date? = nil,
        reviewCount: Int = 0
    ) {
        self.id = UUID()
        self.word = word
        self.languageRaw = language.rawValue
        self.definition = definition
        self.translation = translation
        self.sentence = sentence
        self.bookTitle = bookTitle
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.lastReviewedAt = lastReviewedAt
        self.reviewCount = reviewCount
    }
}
