import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VocabEntry.createdAt, order: .reverse) private var entries: [VocabEntry]

    @State private var selectedEntryID: PersistentIdentifier?
    @State private var searchText: String = ""
    @State private var filter: EntryFilter = .due
    @State private var isAddingWord: Bool = false
    @State private var hasPickedInitialRandom: Bool = false

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

    private var filteredEntries: [VocabEntry] {
        let scopedEntries: [VocabEntry] = switch filter {
        case .all:
            entries
        case .due:
            dueEntries
        case .favorites:
            entries.filter(\.isFavorite)
        case .korean:
            entries.filter { $0.language == .ko }
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
                selection: $selectedEntryID,
                searchText: $searchText,
                filter: $filter
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
            }
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
    }

    private func selectReviewCandidate() {
        let candidates = dueEntries.isEmpty ? entries : dueEntries
        selectedEntryID = candidates.randomElement()?.persistentModelID
        filter = dueEntries.isEmpty ? .all : .due
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
