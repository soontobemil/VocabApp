import SwiftUI
import SwiftData

struct AddWordSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage("lastBookTitle") private var lastBookTitle: String = ""

    @State private var word: String = ""
    @State private var definition: String = ""
    @State private var translation: String = ""
    @State private var sentence: String = ""
    @State private var bookTitle: String = ""
    @State private var isFetching: Bool = false

    private let enricher = EntryEnricher()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add Word")
                .font(.title2)
                .fontWeight(.semibold)

            HStack {
                TextField("Word", text: $word)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { Task { await fetch() } }
                Button("Fetch") { Task { await fetch() } }
                    .disabled(word.trimmingCharacters(in: .whitespaces).isEmpty || isFetching)
            }

            if isFetching {
                ProgressView("Looking up...")
                    .controlSize(.small)
            }

            labeledEditor("Definition", text: $definition)
            labeledEditor("Translation", text: $translation)
            labeledEditor("Sentence (from book)", text: $sentence)

            VStack(alignment: .leading, spacing: 3) {
                Text("Book title")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("", text: $bookTitle)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape)
                Button("Save") { save() }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .buttonStyle(.borderedProminent)
                    .disabled(word.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 480)
        .onAppear {
            if bookTitle.isEmpty {
                bookTitle = lastBookTitle
            }
        }
    }

    @ViewBuilder
    private func labeledEditor(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: text)
                .font(.body)
                .frame(minHeight: 48, maxHeight: 96)
                .padding(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.separator, lineWidth: 1)
                )
        }
    }

    private func fetch() async {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isFetching = true
        defer { isFetching = false }

        let language = Language.detect(from: trimmed)
        let result = await enricher.enrich(word: trimmed, language: language)
        if definition.isEmpty, let fetched = result.definition {
            definition = fetched
        }
        if translation.isEmpty, let fetched = result.translation {
            translation = fetched
        }
    }

    private func save() {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let entry = VocabEntry(
            word: trimmed,
            language: Language.detect(from: trimmed),
            definition: definition.isEmpty ? nil : definition,
            translation: translation.isEmpty ? nil : translation,
            sentence: sentence.isEmpty ? nil : sentence,
            bookTitle: bookTitle.isEmpty ? nil : bookTitle
        )
        modelContext.insert(entry)
        try? modelContext.save()
        lastBookTitle = bookTitle
        dismiss()
    }
}
