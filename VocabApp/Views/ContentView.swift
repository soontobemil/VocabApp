import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VocabEntry.createdAt, order: .reverse) private var entries: [VocabEntry]

    @State private var selectedEntryID: PersistentIdentifier?
    @State private var searchText: String = ""
    @State private var isAddingWord: Bool = false
    @State private var hasPickedInitialRandom: Bool = false

    private var filteredEntries: [VocabEntry] {
        guard !searchText.isEmpty else { return entries }
        let needle = searchText.lowercased()
        return entries.filter { entry in
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
                selection: $selectedEntryID,
                searchText: $searchText
            )
        } detail: {
            Group {
                if let entry = selectedEntry {
                    DetailView(entry: entry)
                } else if entries.isEmpty {
                    EmptyStateView { isAddingWord = true }
                } else {
                    Text("Select a word")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { isAddingWord = true }) {
                    Label("Add Word", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
        .sheet(isPresented: $isAddingWord) {
            AddWordSheet()
        }
        .onAppear {
            if !hasPickedInitialRandom, let random = entries.randomElement() {
                selectedEntryID = random.persistentModelID
                hasPickedInitialRandom = true
            }
        }
    }
}

private struct EmptyStateView: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "book")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No words yet")
                .font(.title2)
            Button("Add your first word", action: action)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
    }
}
