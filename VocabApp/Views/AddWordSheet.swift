import SwiftUI
import SwiftData

struct AddWordSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \VocabEntry.createdAt, order: .reverse) private var existingEntries: [VocabEntry]

    @AppStorage("lastBookTitle") private var lastBookTitle: String = ""

    let onSave: (VocabEntry) -> Void

    @State private var word: String = ""
    @State private var definition: String = ""
    @State private var translation: String = ""
    @State private var sentence: String = ""
    @State private var bookTitle: String = ""
    @State private var isFetching: Bool = false

    @State private var lastFetchedDefinition: String = ""
    @State private var lastFetchedTranslation: String = ""
    @State private var fetchTask: Task<Void, Never>?
    @State private var autocorrectedFrom: String?
    @State private var isApplyingAutocorrection: Bool = false
    @FocusState private var isWordFocused: Bool

    private let enricher = EntryEnricher()
    private let debounceNanos: UInt64 = 500_000_000

    private var trimmedWord: String {
        word.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var duplicateEntry: VocabEntry? {
        guard !trimmedWord.isEmpty else { return nil }
        return existingEntries.first {
            $0.word.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare(trimmedWord) == .orderedSame
        }
    }

    private var detectedLanguage: Language {
        Language.detect(from: trimmedWord)
    }

    private var definitionLabel: String {
        detectedLanguage == .en ? "Definition (English)" : "Definition (Korean)"
    }

    private var translationLabel: String {
        detectedLanguage == .en ? "Meaning (Korean)" : "Meaning (English)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            AddSheetHeader(isFetching: isFetching, detectedLanguage: detectedLanguage)

            VStack(alignment: .leading, spacing: 8) {
                Text("Word")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                HStack {
                    TextField("Type a word from your book...", text: $word)
                        .textFieldStyle(.plain)
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .focused($isWordFocused)
                        .onChange(of: word) { _, _ in
                            if isApplyingAutocorrection {
                                isApplyingAutocorrection = false
                            } else {
                                handleWordChange()
                            }
                        }
                        .onSubmit { triggerFetchNow() }

                    Button {
                        PronunciationSpeaker.shared.speak(trimmedWord, language: detectedLanguage)
                    } label: {
                        Label("Pronounce", systemImage: "speaker.wave.2")
                    }
                    .labelStyle(.iconOnly)
                    .help("Pronounce this word")
                    .disabled(trimmedWord.isEmpty)
                }
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(trimmedWord.isEmpty ? Color.primary.opacity(0.12) : Color.teal.opacity(0.4), lineWidth: 1)
                )
            }

            if let autocorrectedFrom {
                Label("Autocorrected \(autocorrectedFrom) to \(trimmedWord)", systemImage: "text.magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(.teal)
            }

            if let duplicateEntry {
                HStack {
                    Label("Already saved in \(duplicateLocation(for: duplicateEntry))", systemImage: "exclamationmark.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Open Existing") {
                        fetchTask?.cancel()
                        onSave(duplicateEntry)
                        dismiss()
                    }
                }
            }

            labeledEditor(translationLabel, text: $translation)
            labeledEditor(definitionLabel, text: $definition)
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
                Button("Cancel") {
                    fetchTask?.cancel()
                    dismiss()
                }
                .keyboardShortcut(.escape)
                Button("Save + Another") { save(dismissAfterSave: false) }
                    .disabled(trimmedWord.isEmpty)
                Button("Save") { save(dismissAfterSave: true) }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .buttonStyle(.borderedProminent)
                    .disabled(trimmedWord.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 620)
        .onAppear {
            if bookTitle.isEmpty {
                bookTitle = lastBookTitle
            }
            isWordFocused = true
        }
        .onDisappear {
            fetchTask?.cancel()
        }
    }

    @ViewBuilder
    private func labeledEditor(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            TextEditor(text: text)
                .font(.body)
                .frame(minHeight: label.contains("Meaning") ? 72 : 56, maxHeight: label.contains("Definition") ? 104 : 96)
                .padding(7)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.separator, lineWidth: 1)
                )
        }
    }

    private func handleWordChange() {
        if definition == lastFetchedDefinition {
            definition = ""
            lastFetchedDefinition = ""
        }
        if translation == lastFetchedTranslation {
            translation = ""
            lastFetchedTranslation = ""
        }
        autocorrectedFrom = nil

        fetchTask?.cancel()
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isFetching = false
            return
        }
        fetchTask = Task { [trimmed] in
            try? await Task.sleep(nanoseconds: debounceNanos)
            if Task.isCancelled { return }
            await performFetch(for: trimmed)
        }
    }

    private func triggerFetchNow() {
        fetchTask?.cancel()
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        fetchTask = Task { [trimmed] in
            await performFetch(for: trimmed)
        }
    }

    private func performFetch(for trimmed: String) async {
        await MainActor.run { isFetching = true }
        let language = Language.detect(from: trimmed)
        let result = await enricher.enrich(word: trimmed, language: language)
        if Task.isCancelled { return }

        await MainActor.run {
            if word.trimmingCharacters(in: .whitespacesAndNewlines) != trimmed {
                isFetching = false
                return
            }
            if let corrected = result.correctedWord {
                isApplyingAutocorrection = true
                autocorrectedFrom = trimmed
                word = corrected
            }
            if let fetched = result.definition,
               (definition.isEmpty || definition == lastFetchedDefinition) {
                definition = fetched
                lastFetchedDefinition = fetched
            }
            if let fetched = result.translation,
               (translation.isEmpty || translation == lastFetchedTranslation) {
                translation = fetched
                lastFetchedTranslation = fetched
            }
            isFetching = false
        }
    }

    private func duplicateLocation(for entry: VocabEntry) -> String {
        guard let book = entry.bookTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
              !book.isEmpty
        else { return "your library" }
        return book
    }

    private func save(dismissAfterSave: Bool) {
        let trimmed = trimmedWord
        guard !trimmed.isEmpty else { return }

        fetchTask?.cancel()
        let entry = VocabEntry(
            word: trimmed,
            language: detectedLanguage,
            definition: definition.isEmpty ? nil : definition,
            translation: translation.isEmpty ? nil : translation,
            sentence: sentence.isEmpty ? nil : sentence,
            bookTitle: bookTitle.isEmpty ? nil : bookTitle
        )
        modelContext.insert(entry)
        try? modelContext.save()
        lastBookTitle = bookTitle
        onSave(entry)

        if dismissAfterSave {
            dismiss()
        } else {
            resetForNextEntry()
        }
    }

    private func resetForNextEntry() {
        word = ""
        definition = ""
        translation = ""
        sentence = ""
        isFetching = false
        lastFetchedDefinition = ""
        lastFetchedTranslation = ""
        autocorrectedFrom = nil
        isWordFocused = true
    }
}

private struct AddSheetHeader: View {
    let isFetching: Bool
    let detectedLanguage: Language

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Add Word")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Capture the vocab, keep the Korean meaning clean, and save the book context.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Text(detectedLanguage == .en ? "EN -> KO" : "KO -> EN")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())

                if isFetching {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.teal.opacity(0.2), Color.orange.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18)
        )
    }
}
