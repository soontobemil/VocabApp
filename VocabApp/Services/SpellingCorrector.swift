import AppKit
import Foundation

struct SpellingCorrector {
    func correction(for word: String, language: Language) -> String? {
        guard language == .en else { return nil }

        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isSingleEnglishWord(trimmed) else { return nil }

        let range = NSRange(location: 0, length: (trimmed as NSString).length)
        return NSSpellChecker.shared
            .guesses(
                forWordRange: range,
                in: trimmed,
                language: "en",
                inSpellDocumentWithTag: 0
            )?
            .first { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
    }

    private func isSingleEnglishWord(_ word: String) -> Bool {
        guard !word.isEmpty, !word.contains(where: \.isWhitespace) else { return false }
        let allowed = CharacterSet.letters.union(CharacterSet(charactersIn: "'-"))
        return word.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
}
