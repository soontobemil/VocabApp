import SwiftUI
import SwiftData

struct SidebarView: View {
    let entries: [VocabEntry]
    @Binding var selection: PersistentIdentifier?
    @Binding var searchText: String

    var body: some View {
        List(selection: $selection) {
            ForEach(entries) { entry in
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.word)
                        .font(.headline)
                    if let book = entry.bookTitle, !book.isEmpty {
                        Text(book)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .tag(entry.persistentModelID)
            }
        }
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search")
        .navigationTitle("Vocab")
        .frame(minWidth: 220)
    }
}
