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

    var language: Language {
        get { Language(rawValue: languageRaw) ?? .en }
        set { languageRaw = newValue.rawValue }
    }

    init(
        word: String,
        language: Language,
        definition: String? = nil,
        translation: String? = nil,
        sentence: String? = nil,
        bookTitle: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.word = word
        self.languageRaw = language.rawValue
        self.definition = definition
        self.translation = translation
        self.sentence = sentence
        self.bookTitle = bookTitle
        self.createdAt = createdAt
    }
}
