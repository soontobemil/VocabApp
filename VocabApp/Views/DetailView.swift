import SwiftUI
import SwiftData

struct DetailView: View {
    @Bindable var entry: VocabEntry

    private var definitionLabel: String {
        entry.language == .en ? "Definition (English)" : "Definition (Korean)"
    }

    private var translationLabel: String {
        entry.language == .en ? "Translation (Korean)" : "Translation (English)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(entry.word)
                    .font(.system(size: 40, weight: .semibold))
                    .textSelection(.enabled)

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
}

struct LabeledEditor: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $text)
                .font(.body)
                .frame(minHeight: 44, maxHeight: 160)
                .padding(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.separator, lineWidth: 1)
                )
        }
    }
}

struct LabeledField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}
