import Foundation

struct DictionaryClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchEnglishDefinition(for word: String) async -> String? {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty,
              let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(encoded)")
        else { return nil }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let decoded = try JSONDecoder().decode([DictEntry].self, from: data)
            return decoded.first?.meanings.first?.definitions.first?.definition
        } catch {
            return nil
        }
    }
}

private struct DictEntry: Decodable {
    let meanings: [DictMeaning]
}

private struct DictMeaning: Decodable {
    let definitions: [DictDefinition]
}

private struct DictDefinition: Decodable {
    let definition: String
}
