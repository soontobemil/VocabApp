import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VocabEntry.createdAt, order: .reverse) private var entries: [VocabEntry]

    @State private var selectedEntryID: PersistentIdentifier?
    @State private var searchText: String = ""
    @State private var filter: EntryFilter = .due
    @State private var isAddingWord: Bool = false
    @State private var hasPickedInitialRandom: Bool = false
    @State private var selectedBookTitle: String = SidebarView.allBooksTitle
    @State private var isExporting: Bool = false
    @State private var isImporting: Bool = false
    @State private var exportDocument = VocabExportDocument()
    @State private var importErrorMessage: String?

    private var dueEntries: [VocabEntry] {
        entries.filter { $0.isDue() }
    }

    private var favoriteEntries: [VocabEntry] {
        entries.filter(\.isFavorite)
    }

    private var reviewedTodayCount: Int {
        entries.filter { entry in
            guard let lastReviewedAt = entry.lastReviewedAt else { return false }
            return Calendar.current.isDateInToday(lastReviewedAt)
        }.count
    }

    private var newTodayCount: Int {
        entries.filter { Calendar.current.isDateInToday($0.createdAt) }.count
    }

    private var bookTitles: [String] {
        Array(Set(entries.compactMap { clean($0.bookTitle) })).sorted()
    }

    private var filteredEntries: [VocabEntry] {
        let deckEntries = entriesForSelectedBook
        let scopedEntries: [VocabEntry] = switch filter {
        case .all:
            deckEntries
        case .due:
            deckEntries.filter { $0.isDue() }
        case .favorites:
            deckEntries.filter(\.isFavorite)
        case .korean:
            deckEntries.filter { $0.language == .ko }
        }

        guard !searchText.isEmpty else { return scopedEntries }
        let needle = searchText.lowercased()
        return scopedEntries.filter { entry in
            entry.word.lowercased().contains(needle)
                || (entry.definition ?? "").lowercased().contains(needle)
                || (entry.translation ?? "").lowercased().contains(needle)
                || (entry.sentence ?? "").lowercased().contains(needle)
                || (entry.bookTitle ?? "").lowercased().contains(needle)
        }
    }

    private var entriesForSelectedBook: [VocabEntry] {
        guard selectedBookTitle != SidebarView.allBooksTitle else { return entries }
        return entries.filter { clean($0.bookTitle) == selectedBookTitle }
    }

    private var selectedEntry: VocabEntry? {
        guard let selectedEntryID else { return nil }
        return entries.first(where: { $0.persistentModelID == selectedEntryID })
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                entries: filteredEntries,
                totalCount: entries.count,
                dueCount: dueEntries.count,
                favoriteCount: favoriteEntries.count,
                reviewedTodayCount: reviewedTodayCount,
                newTodayCount: newTodayCount,
                bookTitles: bookTitles,
                selection: $selectedEntryID,
                searchText: $searchText,
                filter: $filter,
                selectedBookTitle: $selectedBookTitle
            )
        } detail: {
            Group {
                if let entry = selectedEntry {
                    DetailView(
                        entry: entry,
                        showNextReview: selectReviewCandidate
                    )
                } else if entries.isEmpty {
                    EmptyStateView { isAddingWord = true }
                } else {
                    NoSelectionView(
                        dueCount: dueEntries.count,
                        addWord: { isAddingWord = true },
                        startReview: selectReviewCandidate
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        exportDocument = VocabExportDocument(entries: entries.map(VocabEntrySnapshot.init))
                        isExporting = true
                    } label: {
                        Label("Export Library", systemImage: "square.and.arrow.up")
                    }
                    .disabled(entries.isEmpty)

                    Button {
                        isImporting = true
                    } label: {
                        Label("Import Library", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Label("Library", systemImage: "tray.full")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: selectReviewCandidate) {
                    Label("Review", systemImage: "checkmark.circle")
                }
                .disabled(entries.isEmpty)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: { isAddingWord = true }) {
                    Label("Add Word", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
        .sheet(isPresented: $isAddingWord) {
            AddWordSheet { entry in
                selectedEntryID = entry.persistentModelID
                filter = .all
                if let bookTitle = clean(entry.bookTitle) {
                    selectedBookTitle = bookTitle
                }
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "vocabapp-export"
        ) { result in
            if case .failure(let error) = result {
                importErrorMessage = error.localizedDescription
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
            importEntries(from: result)
        }
        .alert("Library Import/Export Failed", isPresented: Binding(
            get: { importErrorMessage != nil },
            set: { if !$0 { importErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { importErrorMessage = nil }
        } message: {
            Text(importErrorMessage ?? "")
        }
        .onAppear {
            if !hasPickedInitialRandom, let random = entries.randomElement() {
                selectedEntryID = random.persistentModelID
                hasPickedInitialRandom = true
            }
        }
        .onChange(of: filter) { _, _ in
            guard let selectedEntryID,
                  filteredEntries.contains(where: { $0.persistentModelID == selectedEntryID })
            else {
                selectedEntryID = filteredEntries.first?.persistentModelID
                return
            }
        }
        .onChange(of: selectedBookTitle) { _, _ in
            guard let selectedEntryID,
                  filteredEntries.contains(where: { $0.persistentModelID == selectedEntryID })
            else {
                selectedEntryID = filteredEntries.first?.persistentModelID
                return
            }
        }
    }

    private func selectReviewCandidate() {
        let deckEntries = entriesForSelectedBook
        let deckDueEntries = deckEntries.filter { $0.isDue() }
        let candidates = deckDueEntries.isEmpty ? deckEntries : deckDueEntries
        selectedEntryID = candidates.randomElement()?.persistentModelID
        filter = deckDueEntries.isEmpty ? .all : .due
    }

    private func importEntries(from result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let didStartAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            let snapshots = try JSONDecoder.vocabApp.decode([VocabEntrySnapshot].self, from: data)
            let existingKeys = Set(entries.map(importKey(for:)))
            snapshots
                .filter { !existingKeys.contains(importKey(for: $0)) }
                .map { $0.makeEntry() }
                .forEach(modelContext.insert)
            try modelContext.save()
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    private func importKey(for entry: VocabEntry) -> String {
        "\(entry.languageRaw)|\(entry.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())|\(clean(entry.bookTitle) ?? "")"
    }

    private func importKey(for snapshot: VocabEntrySnapshot) -> String {
        "\(snapshot.languageRaw)|\(snapshot.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())|\(clean(snapshot.bookTitle) ?? "")"
    }

    private func clean(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty
        else { return nil }
        return trimmed
    }
}

private struct EmptyStateView: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "book.pages.fill")
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(.white, .orange)
                .padding(18)
                .background(
                    LinearGradient(
                        colors: [Color.teal.opacity(0.85), Color.orange.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 24)
                )

            VStack(spacing: 6) {
                Text("Build a bilingual reading deck")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Add a word from your book, keep the original sentence, then review it later as a flashcard.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }

            Button("Add your first word", action: action)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
        .padding(32)
    }
}

private struct NoSelectionView: View {
    let dueCount: Int
    let addWord: () -> Void
    let startReview: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: dueCount > 0 ? "rectangle.stack.badge.play.fill" : "sparkles")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(dueCount > 0 ? .orange : .teal)
            VStack(spacing: 5) {
                Text(dueCount > 0 ? "\(dueCount) words ready to review" : "All caught up")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(dueCount > 0 ? "Start with a random due card and reveal the meaning when you are ready." : "Add more words or browse a random saved card.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Button("Add Word", action: addWord)
                Button(dueCount > 0 ? "Start Review" : "Browse Random", action: startReview)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
    }
}
