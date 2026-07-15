import SwiftData
import SwiftUI

struct WatchlistView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WatchlistEntry.createdAt, order: .reverse) private var entries: [WatchlistEntry]

    var body: some View {
        MashhadBackground {
            Group {
                if entries.isEmpty {
                    EmptyStateView(
                        title: "watchlist_empty_title",
                        message: "watchlist_empty_message",
                        symbol: "bookmark",
                        actionTitle: "discover_search_action"
                    ) {
                        environment.router.selectedTab = .discover
                    }
                } else {
                    List {
                        ForEach(entries) { entry in
                            NavigationLink(value: AppRouter.Route.mediaDetails(media(from: entry))) {
                                WatchlistRow(entry: entry, configuration: environment.configuration)
                            }
                            .listRowBackground(MashhadTheme.surface)
                        }
                        .onDelete(perform: delete)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .padding(.horizontal, entries.isEmpty ? MashhadTheme.pagePadding : 0)
        }
        .navigationTitle("watchlist_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func delete(at offsets: IndexSet) {
        offsets.map { entries[$0] }.forEach(modelContext.delete)
    }

    private func media(from entry: WatchlistEntry) -> MediaSummary {
        MediaSummary(
            id: entry.mediaID,
            kind: MediaKind(rawValue: entry.kindRaw) ?? .movie,
            title: entry.title,
            originalTitle: nil,
            overview: "",
            posterPath: entry.posterPath,
            backdropPath: nil,
            releaseDate: nil,
            voteAverage: 0,
            genreNames: [],
            numberOfSeasons: nil
        )
    }
}

private struct WatchlistRow: View {
    let entry: WatchlistEntry
    let configuration: AppConfiguration

    var body: some View {
        HStack(spacing: 12) {
            PosterImage(path: entry.posterPath, configuration: configuration)
                .frame(width: 52, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.title)
                    .font(.headline)
                    .foregroundStyle(MashhadTheme.textPrimary)
                Text(LocalizedStringKey(entry.status.titleKey))
                    .font(.subheadline)
                    .foregroundStyle(MashhadTheme.accentSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}
