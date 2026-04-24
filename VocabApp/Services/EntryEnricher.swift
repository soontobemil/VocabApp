import Foundation

struct EnrichedWord {
    let definition: String?
    let translation: String?
}

struct EntryEnricher {
    let dictionary: DictionaryClient
    let translator: TranslationClient

    init(
        dictionary: DictionaryClient = DictionaryClient(),
        translator: TranslationClient = TranslationClient()
    ) {
        self.dictionary = dictionary
        self.translator = translator
    }

    func enrich(word: String, language: Language) async -> EnrichedWord {
        async let definitionTask = fetchDefinition(word: word, language: language)
        async let translationTask = translator.translate(
            word,
            from: language,
            to: language == .en ? .ko : .en
        )
        return EnrichedWord(
            definition: await definitionTask,
            translation: await translationTask
        )
    }

    private func fetchDefinition(word: String, language: Language) async -> String? {
        switch language {
        case .en:
            return await dictionary.fetchEnglishDefinition(for: word)
        case .ko:
            return nil
        }
    }
}
