import AVFoundation
import Foundation

@MainActor
final class PronunciationSpeaker {
    static let shared = PronunciationSpeaker()

    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

    func speak(_ text: String, language: Language) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: trimmed)
        if let voice = Self.voice(for: language) {
            utterance.voice = voice
        }
        synthesizer.speak(utterance)
    }

    private static func voice(for language: Language) -> AVSpeechSynthesisVoice? {
        AVSpeechSynthesisVoice(language: language.speechLocaleIdentifier)
            ?? AVSpeechSynthesisVoice.speechVoices().first {
                $0.language.lowercased().hasPrefix(language.rawValue)
            }
    }
}

private extension Language {
    var speechLocaleIdentifier: String {
        switch self {
        case .en:
            return "en-US"
        case .ko:
            return "ko-KR"
        }
    }
}
