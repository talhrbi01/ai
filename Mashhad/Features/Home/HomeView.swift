import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(AppEnvironment.self) private var environment
    @Query(sort: \WatchlistEntry.createdAt, order: .reverse) private var watchlist: [WatchlistEntry]
    @State private var state: LoadState<[MediaSummary]> = .idle

    var body: some View {
        MashhadBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    header
                    SectionHeader(title: "home_trending")
                    content
                    SectionHeader(title: "home_watch_next")
                    watchNextContent
                }
                .padding(.horizontal, MashhadTheme.pagePadding)
                .padding(.vertical, 20)
            }
            .refreshable { await load() }
        }
        .navigationTitle("tab_home")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: environment.configuration.tmdbAPIKey) { await load() }
    }

    @ViewBuilder
    private var watchNextContent: some View {
        if watchlist.isEmpty {
            EmptyStateView(
                title: "home_empty_watchlist_title",
                message: "home_empty_watchlist_message",
                symbol: "bookmark"
            )
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 14) {
                    ForEach(watchlist) { entry in
                        let item = media(from: entry)
                        NavigationLink(value: AppRouter.Route.mediaDetails(item)) {
                            MediaPosterCard(media: item, configuration: environment.configuration)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("home_greeting")
                .font(.title.bold())
                .foregroundStyle(MashhadTheme.textPrimary)
            Text("home_subtitle")
                .font(.subheadline)
                .foregroundStyle(MashhadTheme.textSecondary)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity).padding(.vertical, 50)
        case .failed(let message):
            ErrorStateView(message: message) { Task { await load() } }
        case .loaded(let media):
            if media.isEmpty {
                EmptyStateView(title: "home_no_trending_title", message: "home_no_trending_message", symbol: "film")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 14) {
                        ForEach(media) { item in
                            NavigationLink(value: AppRouter.Route.mediaDetails(item)) {
                                MediaPosterCard(media: item, configuration: environment.configuration)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    @MainActor
    private func load() async {
        state = .loading
        do {
            state = .loaded(try await environment.tmdbService.trending())
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
