import SwiftUI
import SwiftData

enum EntryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case due = "Due"
    case favorites = "Starred"
    case korean = "KO"

    var id: Self { self }
}

struct SidebarView: View {
    let entries: [VocabEntry]
    let totalCount: Int
    let dueCount: Int
    let favoriteCount: Int
    let reviewedTodayCount: Int
    @Binding var selection: PersistentIdentifier?
    @Binding var searchText: String
    @Binding var filter: EntryFilter

    var body: some View {
        VStack(spacing: 0) {
            SidebarHeader(
                totalCount: totalCount,
                dueCount: dueCount,
                favoriteCount: favoriteCount,
                reviewedTodayCount: reviewedTodayCount,
                filter: $filter
            )

            List(selection: $selection) {
                ForEach(entries) { entry in
                    EntryRow(entry: entry, subtitle: rowSubtitle(for: entry))
                        .tag(entry.persistentModelID)
                }
            }
        }
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search")
        .navigationTitle("Vocab")
        .frame(minWidth: 260)
    }

    private func rowSubtitle(for entry: VocabEntry) -> String {
        if let book = entry.bookTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
           !book.isEmpty {
            return book
        }
        if let sentence = entry.sentence?.trimmingCharacters(in: .whitespacesAndNewlines),
           !sentence.isEmpty {
            return sentence
        }
        if let translation = entry.translation?.trimmingCharacters(in: .whitespacesAndNewlines),
           !translation.isEmpty {
            return translation
        }
        return "Added \(entry.createdAt.formatted(date: .abbreviated, time: .omitted))"
    }
}

private struct SidebarHeader: View {
    let totalCount: Int
    let dueCount: Int
    let favoriteCount: Int
    let reviewedTodayCount: Int
    @Binding var filter: EntryFilter

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reading Deck")
                        .font(.headline)
                    Text("\(totalCount) saved words")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(dueCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(dueCount > 0 ? .orange : .green)
                    Text("due")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                StatPill(title: "Today", value: reviewedTodayCount, tint: .green)
                StatPill(title: "Starred", value: favoriteCount, tint: .yellow)
            }

            Picker("Filter", selection: $filter) {
                ForEach(EntryFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [Color.teal.opacity(0.18), Color.orange.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

private struct StatPill: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tint)
                .frame(width: 7, height: 7)
            Text(title)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .fontWeight(.semibold)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.thinMaterial, in: Capsule())
    }
}

private struct EntryRow: View {
    let entry: VocabEntry
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(entry.word)
                    .font(.headline)
                    .lineLimit(1)
                Spacer(minLength: 6)
                if entry.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
                Text(entry.language.rawValue.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack(spacing: 6) {
                ReviewBadge(isDue: entry.isDue())
                if entry.reviewCount > 0 {
                    Text("\(entry.reviewCount)x reviewed")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption2)
        }
        .padding(.vertical, 5)
    }
}

private struct ReviewBadge: View {
    let isDue: Bool

    var body: some View {
        Label(isDue ? "Due" : "Reviewed", systemImage: isDue ? "circle.fill" : "checkmark.circle.fill")
            .labelStyle(.titleAndIcon)
            .foregroundStyle(isDue ? .orange : .green)
    }
}
