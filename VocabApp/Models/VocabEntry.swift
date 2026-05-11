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
    var nextReviewAt: Date?
    var reviewIntervalDays: Int = 0
    var easeFactor: Double = 2.5

    var language: Language {
        get { Language(rawValue: languageRaw) ?? .en }
        set { languageRaw = newValue.rawValue }
    }

    func isDue(on date: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard let nextReviewAt else {
            guard let lastReviewedAt else { return true }
            return !calendar.isDate(lastReviewedAt, inSameDayAs: date)
        }
        return nextReviewAt <= date
    }

    func markReviewed(at date: Date = Date()) {
        markReviewed(quality: .good, at: date)
    }

    func markReviewed(quality: ReviewQuality, at date: Date = Date(), calendar: Calendar = .current) {
        lastReviewedAt = date
        reviewCount += 1

        switch quality {
        case .again:
            reviewIntervalDays = 0
            easeFactor = max(1.3, easeFactor - 0.2)
        case .hard:
            reviewIntervalDays = max(1, reviewIntervalDays)
            easeFactor = max(1.3, easeFactor - 0.15)
        case .good:
            if reviewIntervalDays == 0 {
                reviewIntervalDays = 1
            } else if reviewIntervalDays == 1 {
                reviewIntervalDays = 3
            } else {
                reviewIntervalDays = max(1, Int((Double(reviewIntervalDays) * easeFactor).rounded()))
            }
        case .easy:
            if reviewIntervalDays == 0 {
                reviewIntervalDays = 3
            } else {
                reviewIntervalDays = max(4, Int((Double(reviewIntervalDays) * (easeFactor + 0.35)).rounded()))
            }
            easeFactor = min(3.2, easeFactor + 0.15)
        }

        nextReviewAt = calendar.date(byAdding: .day, value: reviewIntervalDays, to: date)
    }

    var clozeSentence: String? {
        guard let sentence = sentence?.trimmingCharacters(in: .whitespacesAndNewlines),
              !sentence.isEmpty
        else { return nil }

        let escaped = NSRegularExpression.escapedPattern(for: word)
        guard let regex = try? NSRegularExpression(pattern: "\\b\(escaped)\\b", options: [.caseInsensitive]) else {
            return sentence
        }
        let range = NSRange(sentence.startIndex..<sentence.endIndex, in: sentence)
        let blanked = regex.stringByReplacingMatches(in: sentence, range: range, withTemplate: "_____")
        return blanked == sentence ? sentence : blanked
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
        reviewCount: Int = 0,
        nextReviewAt: Date? = nil,
        reviewIntervalDays: Int = 0,
        easeFactor: Double = 2.5
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
        self.nextReviewAt = nextReviewAt
        self.reviewIntervalDays = reviewIntervalDays
        self.easeFactor = easeFactor
    }
}

enum ReviewQuality: String, CaseIterable, Identifiable {
    case again = "Again"
    case hard = "Hard"
    case good = "Good"
    case easy = "Easy"

    var id: Self { self }

    var intervalHint: String {
        switch self {
        case .again:
            return "today"
        case .hard:
            return "1d"
        case .good:
            return "next"
        case .easy:
            return "later"
        }
    }
}
