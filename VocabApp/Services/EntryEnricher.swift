import Foundation

struct EnrichedWord {
    let correctedWord: String?
    let definition: String?
    let translation: String?
    let sentence: String?
}

struct EntryEnricher {
    let dictionary: DictionaryClient
    let translator: TranslationClient
    let spellingCorrector: SpellingCorrector
    let glossary: KoreanGlossary
    let exampleGenerator: ExampleSentenceGenerator

    init(
        dictionary: DictionaryClient = DictionaryClient(),
        translator: TranslationClient = TranslationClient(),
        spellingCorrector: SpellingCorrector = SpellingCorrector(),
        glossary: KoreanGlossary = KoreanGlossary(),
        exampleGenerator: ExampleSentenceGenerator = ExampleSentenceGenerator()
    ) {
        self.dictionary = dictionary
        self.translator = translator
        self.spellingCorrector = spellingCorrector
        self.glossary = glossary
        self.exampleGenerator = exampleGenerator
    }

    func enrich(word: String, language: Language) async -> EnrichedWord {
        let lookup = await fetchDefinition(word: word, language: language)
        let targetLanguage: Language = language == .en ? .ko : .en
        let translation = await translate(
            lookup: lookup,
            from: language,
            to: targetLanguage
        )
        return EnrichedWord(
            correctedWord: lookup.correctedWord,
            definition: lookup.definition?.displayText,
            translation: translation,
            sentence: exampleGenerator.sentence(for: lookup.word, definition: lookup.definition)
        )
    }

    private func translate(lookup: DefinitionLookup, from source: Language, to target: Language) async -> String? {
        if source == .en,
           target == .ko,
           let glossaryMeaning = glossary.meaning(for: lookup.word) {
            return glossaryMeaning
        }

        if source == .en,
           let definition = lookup.definition {
            let translatedSenses = await translateSenses(definition.translationSeeds, from: source, to: target)
            if !translatedSenses.isEmpty {
                if translatedSenses.count == 1 {
                    return translatedSenses[0]
                }
                return formattedMeanings(translatedSenses)
            }
        }

        if let translation = await translator.translate(lookup.word, from: source, to: target) {
            return source == .en && target == .ko ? cleanKoreanGloss(translation) : translation
        }

        guard source == .en,
              let translationSeed = lookup.definition?.translationSeeds.first,
              translationSeed.caseInsensitiveCompare(lookup.word) != .orderedSame
        else { return nil }

        guard let translation = await translator.translate(translationSeed, from: source, to: target) else {
            return nil
        }
        return source == .en && target == .ko ? cleanKoreanGloss(translation) : translation
    }

    private func translateSenses(_ senses: [String], from source: Language, to target: Language) async -> [String] {
        var translations: [String] = []
        for sense in senses {
            guard let translation = await translator.translate(sense, from: source, to: target) else {
                continue
            }
            translations.append(source == .en && target == .ko ? cleanKoreanGloss(translation) : translation)
        }
        return translations
    }

    private func formattedMeanings(_ meanings: [String]) -> String {
        meanings.enumerated()
            .map { index, meaning in "\(index + 1)) \(meaning)" }
            .joined(separator: "\n")
    }

    private func cleanKoreanGloss(_ translation: String) -> String {
        var cleaned = translation
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".。"))

        for suffix in ["의 의미", " 의미"] {
            if cleaned.hasSuffix(suffix) {
                cleaned = String(cleaned.dropLast(suffix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        let suffixReplacements = [
            ("돌아가기", "돌아감"),
            ("복귀하기", "복귀"),
            ("여행하기", "여행"),
            ("하기", "함"),
            ("되기", "됨")
        ]
        for (suffix, replacement) in suffixReplacements {
            if cleaned.hasSuffix(suffix) {
                return String(cleaned.dropLast(suffix.count)) + replacement
            }
        }

        return cleaned
    }

    private func fetchDefinition(word: String, language: Language) async -> DefinitionLookup {
        switch language {
        case .en:
            if let definition = await dictionary.fetchEnglishDefinition(for: word) {
                return DefinitionLookup(word: word, correctedWord: nil, definition: definition)
            }
            guard let corrected = spellingCorrector.correction(for: word, language: language),
                  let definition = await dictionary.fetchEnglishDefinition(for: corrected)
            else {
                return DefinitionLookup(word: word, correctedWord: nil, definition: nil)
            }
            return DefinitionLookup(word: corrected, correctedWord: corrected, definition: definition)
        case .ko:
            return DefinitionLookup(word: word, correctedWord: nil, definition: nil)
        }
    }
}

private struct DefinitionLookup {
    let word: String
    let correctedWord: String?
    let definition: DictionaryDefinition?
}
