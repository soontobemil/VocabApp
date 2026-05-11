import Foundation

struct TranslationClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func translate(_ text: String, from source: Language, to target: Language) async -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              source != target,
              var components = URLComponents(string: "https://api.mymemory.translated.net/get")
        else { return nil }

        components.queryItems = [
            URLQueryItem(name: "q", value: trimmed),
            URLQueryItem(name: "langpair", value: "\(source.rawValue)|\(target.rawValue)")
        ]

        guard let url = components.url else { return nil }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let decoded = try JSONDecoder().decode(MyMemoryResponse.self, from: data)
            let translated = decoded.responseData.translatedText
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if translated.isEmpty { return nil }
            if translated.caseInsensitiveCompare(trimmed) == .orderedSame { return nil }
            return dedupeRepeatedSegments(in: translated)
        } catch {
            return nil
        }
    }

    private func dedupeRepeatedSegments(in translated: String) -> String {
        let separators = CharacterSet(charactersIn: ",;")
        let segments = translated
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard segments.count > 1 else { return translated }

        var seen = Set<String>()
        let deduped = segments.filter { segment in
            let key = segment.trimmingCharacters(in: .punctuationCharacters).lowercased()
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }

        return deduped.joined(separator: ", ")
    }
}

private struct MyMemoryResponse: Decodable {
    let responseData: ResponseData
    struct ResponseData: Decodable {
        let translatedText: String
    }
}
