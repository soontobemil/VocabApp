import Foundation
import UniformTypeIdentifiers
import SwiftUI

struct VocabEntrySnapshot: Codable {
    let word: String
    let languageRaw: String
    let definition: String?
    let translation: String?
    let sentence: String?
    let bookTitle: String?
    let createdAt: Date
    let isFavorite: Bool
    let lastReviewedAt: Date?
    let reviewCount: Int
    let nextReviewAt: Date?
    let reviewIntervalDays: Int
    let easeFactor: Double

    enum CodingKeys: String, CodingKey {
        case word
        case languageRaw
        case language
        case definition
        case translation
        case meaning
        case sentence
        case bookTitle
        case createdAt
        case isFavorite
        case lastReviewedAt
        case reviewCount
        case nextReviewAt
        case reviewIntervalDays
        case easeFactor
    }

    init(entry: VocabEntry) {
        word = entry.word
        languageRaw = entry.languageRaw
        definition = entry.definition
        translation = entry.translation
        sentence = entry.sentence
        bookTitle = entry.bookTitle
        createdAt = entry.createdAt
        isFavorite = entry.isFavorite
        lastReviewedAt = entry.lastReviewedAt
        reviewCount = entry.reviewCount
        nextReviewAt = entry.nextReviewAt
        reviewIntervalDays = entry.reviewIntervalDays
        easeFactor = entry.easeFactor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        word = try container.decode(String.self, forKey: .word)
        languageRaw = try container.decodeIfPresent(String.self, forKey: .languageRaw)
            ?? container.decodeIfPresent(String.self, forKey: .language)
            ?? Language.detect(from: word).rawValue
        definition = try container.decodeIfPresent(String.self, forKey: .definition)
        translation = try container.decodeIfPresent(String.self, forKey: .translation)
            ?? container.decodeIfPresent(String.self, forKey: .meaning)
        sentence = try container.decodeIfPresent(String.self, forKey: .sentence)
        bookTitle = try container.decodeIfPresent(String.self, forKey: .bookTitle)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        lastReviewedAt = try container.decodeIfPresent(Date.self, forKey: .lastReviewedAt)
        reviewCount = try container.decodeIfPresent(Int.self, forKey: .reviewCount) ?? 0
        nextReviewAt = try container.decodeIfPresent(Date.self, forKey: .nextReviewAt)
        reviewIntervalDays = try container.decodeIfPresent(Int.self, forKey: .reviewIntervalDays) ?? 0
        easeFactor = try container.decodeIfPresent(Double.self, forKey: .easeFactor) ?? 2.5
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(word, forKey: .word)
        try container.encode(languageRaw, forKey: .languageRaw)
        try container.encodeIfPresent(definition, forKey: .definition)
        try container.encodeIfPresent(translation, forKey: .translation)
        try container.encodeIfPresent(sentence, forKey: .sentence)
        try container.encodeIfPresent(bookTitle, forKey: .bookTitle)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encodeIfPresent(lastReviewedAt, forKey: .lastReviewedAt)
        try container.encode(reviewCount, forKey: .reviewCount)
        try container.encodeIfPresent(nextReviewAt, forKey: .nextReviewAt)
        try container.encode(reviewIntervalDays, forKey: .reviewIntervalDays)
        try container.encode(easeFactor, forKey: .easeFactor)
    }

    func makeEntry() -> VocabEntry {
        VocabEntry(
            word: word,
            language: Language(rawValue: languageRaw) ?? .en,
            definition: definition,
            translation: translation,
            sentence: sentence,
            bookTitle: bookTitle,
            createdAt: createdAt,
            isFavorite: isFavorite,
            lastReviewedAt: lastReviewedAt,
            reviewCount: reviewCount,
            nextReviewAt: nextReviewAt,
            reviewIntervalDays: reviewIntervalDays,
            easeFactor: easeFactor
        )
    }
}

struct VocabExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var entries: [VocabEntrySnapshot]

    init(entries: [VocabEntrySnapshot] = []) {
        self.entries = entries
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            entries = []
            return
        }
        entries = try JSONDecoder.vocabApp.decode([VocabEntrySnapshot].self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder.vocabApp.encode(entries)
        return FileWrapper(regularFileWithContents: data)
    }
}

extension JSONEncoder {
    static var vocabApp: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

extension JSONDecoder {
    static var vocabApp: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
