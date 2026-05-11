import SwiftUI
import SwiftData

struct DetailView: View {
    @Bindable var entry: VocabEntry
    let showNextReview: () -> Void

    private var definitionLabel: String {
        entry.language == .en ? "Definition (English)" : "Definition (Korean)"
    }

    private var translationLabel: String {
        entry.language == .en ? "Meaning (Korean)" : "Meaning (English)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                WordHero(
                    entry: entry,
                    reviewSummary: reviewSummary,
                    bookTitle: clean(entry.bookTitle)
                )

                ReviewCard(
                    entry: entry,
                    showNextReview: showNextReview
                )

                LabeledEditor(
                    label: definitionLabel,
                    text: Binding(
                        get: { entry.definition ?? "" },
                        set: { entry.definition = $0.isEmpty ? nil : $0 }
                    )
                )

                LabeledEditor(
                    label: translationLabel,
                    text: Binding(
                        get: { entry.translation ?? "" },
                        set: { entry.translation = $0.isEmpty ? nil : $0 }
                    )
                )

                LabeledEditor(
                    label: "Sentence",
                    text: Binding(
                        get: { entry.sentence ?? "" },
                        set: { entry.sentence = $0.isEmpty ? nil : $0 }
                    )
                )

                LabeledField(
                    label: "Book",
                    text: Binding(
                        get: { entry.bookTitle ?? "" },
                        set: { entry.bookTitle = $0.isEmpty ? nil : $0 }
                    )
                )

                Text("Added \(entry.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var reviewSummary: String {
        if let lastReviewedAt = entry.lastReviewedAt {
            return "Reviewed \(entry.reviewCount)x, last \(lastReviewedAt.formatted(date: .abbreviated, time: .omitted))"
        }
        return entry.isDue() ? "New or due for first review" : "Ready"
    }

    private func clean(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty
        else { return nil }
        return trimmed
    }
}

private struct WordHero: View {
    @Bindable var entry: VocabEntry
    let reviewSummary: String
    let bookTitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        LanguageBadge(language: entry.language)
                        if entry.isDue() {
                            Text("Due")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.orange.opacity(0.14), in: Capsule())
                        }
                    }

                    Text(entry.word)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .lineLimit(2)
                        .minimumScaleFactor(0.65)
                        .textSelection(.enabled)

                    HStack(spacing: 10) {
                        Text(reviewSummary)
                        if let bookTitle {
                            Text("From \(bookTitle)")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        PronunciationSpeaker.shared.speak(entry.word, language: entry.language)
                    } label: {
                        Label("Pronounce", systemImage: "speaker.wave.2")
                    }
                    .help("Pronounce this word")

                    Button {
                        entry.isFavorite.toggle()
                    } label: {
                        Label(entry.isFavorite ? "Starred" : "Star", systemImage: entry.isFavorite ? "star.fill" : "star")
                    }
                    .foregroundStyle(entry.isFavorite ? .yellow : .primary)
                    .help(entry.isFavorite ? "Remove from starred words" : "Star this word")
                }
                .labelStyle(.iconOnly)
            }
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [Color.teal.opacity(0.24), Color.orange.opacity(0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct LanguageBadge: View {
    let language: Language

    var body: some View {
        Text(language == .en ? "EN -> KO" : "KO -> EN")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.regularMaterial, in: Capsule())
    }
}

private struct ReviewCard: View {
    @Bindable var entry: VocabEntry
    let showNextReview: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(entry.isDue() ? "Study card" : "Recently reviewed", systemImage: entry.isDue() ? "rectangle.stack.badge.play" : "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(entry.isDue() ? .orange : .green)
                Spacer()
                Button {
                    PronunciationSpeaker.shared.speak(entry.word, language: entry.language)
                } label: {
                    Label("Pronounce", systemImage: "speaker.wave.2")
                }
                .help("Pronounce this word")
            }

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    if let translation = clean(entry.translation) {
                        Text(translation)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .textSelection(.enabled)
                    }
                    if let definition = clean(entry.definition) {
                        Text(definition)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    if clean(entry.translation) == nil && clean(entry.definition) == nil {
                        Text("Add a meaning or definition to make this card useful.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .padding(18)
            .background(.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))

            if let sentence = clean(entry.sentence) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Context")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Text(sentence)
                        .font(.body)
                        .italic()
                        .textSelection(.enabled)
                }
            }

            HStack {
                Button {
                    entry.markReviewed()
                } label: {
                    Label("Mark Reviewed", systemImage: "checkmark.circle")
                }
                .keyboardShortcut(.return, modifiers: [])

                Button {
                    showNextReview()
                } label: {
                    Label("Next Word", systemImage: "arrow.right")
                }
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(entry.isDue() ? .orange.opacity(0.25) : .green.opacity(0.2), lineWidth: 1)
        )
    }

    private func clean(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty
        else { return nil }
        return trimmed
    }
}

struct LabeledEditor: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            TextEditor(text: $text)
                .font(.body)
                .frame(minHeight: 54, maxHeight: 170)
                .padding(8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.separator, lineWidth: 1)
                )
        }
    }
}

struct LabeledField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}
