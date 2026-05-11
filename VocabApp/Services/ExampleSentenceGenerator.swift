import Foundation

struct ExampleSentenceGenerator {
    func sentence(for word: String, definition: DictionaryDefinition?) -> String? {
        if let example = definition?.examples.first,
           !example.isEmpty {
            return example
        }

        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let seed = definition?.translationSeeds.first,
           !seed.isEmpty {
            return "The author uses \"\(trimmed)\" to suggest \(seed)."
        }

        return "I wrote down \"\(trimmed)\" because it felt important in this passage."
    }
}
