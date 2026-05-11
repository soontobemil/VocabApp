import Foundation

struct DictionaryDefinition {
    let displayText: String
    let translationSeeds: [String]
}

struct DictionaryClient {
    private let session: URLSession
    private let maxDefinitionCount = 5

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchEnglishDefinition(for word: String) async -> DictionaryDefinition? {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty,
              let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(encoded)")
        else { return nil }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let decoded = try JSONDecoder().decode([DictEntry].self, from: data)
            return formatDefinitions(from: decoded)
        } catch {
            return nil
        }
    }

    private func formatDefinitions(from entries: [DictEntry]) -> DictionaryDefinition? {
        var seen = Set<String>()
        let definitions = Array(entries
            .flatMap(\.meanings)
            .flatMap { meaning in
                meaning.definitions.map { definition in
                    let cleaned = definition.definition.trimmingCharacters(in: .whitespacesAndNewlines)
                    let glossSeed = koreanGlossSeed(from: cleaned)
                    if meaning.partOfSpeech.isEmpty {
                        return (display: cleaned, plain: glossSeed)
                    }
                    return (display: "(\(meaning.partOfSpeech)) \(cleaned)", plain: glossSeed)
                }
            }
            .filter { !$0.display.isEmpty }
            .filter { definition in
                let key = definition.display.lowercased()
                if seen.contains(key) {
                    return false
                }
                seen.insert(key)
                return true
            }
            .prefix(maxDefinitionCount))

        guard !definitions.isEmpty else { return nil }
        let displayText = definitions.enumerated()
            .map { index, definition in "\(index + 1)) \(definition.display)" }
            .joined(separator: "\n")
        return DictionaryDefinition(
            displayText: displayText,
            translationSeeds: definitions.map(\.plain)
        )
    }

    private func koreanGlossSeed(from definition: String) -> String {
        var seed = definition
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))

        if let wherebyRange = seed.range(of: " whereby ", options: .caseInsensitive) {
            seed = String(seed[..<wherebyRange.lowerBound])
        }

        let commaParts = seed
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if commaParts.count > 1,
           commaParts[0].lowercased().contains("action of") {
            seed = commaParts[1]
        }

        let lowercaseSeed = seed.lowercased()
        for prefix in ["an action of ", "a action of ", "the action of ", "an instance of ", "a state of "] {
            if lowercaseSeed.hasPrefix(prefix) {
                seed = String(seed.dropFirst(prefix.count))
                break
            }
        }

        for article in ["a ", "an ", "the "] {
            if seed.lowercased().hasPrefix(article) {
                seed = String(seed.dropFirst(article.count))
                break
            }
        }

        return seed.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct DictEntry: Decodable {
    let meanings: [DictMeaning]
}

private struct DictMeaning: Decodable {
    let partOfSpeech: String
    let definitions: [DictDefinition]
}

private struct DictDefinition: Decodable {
    let definition: String
}
