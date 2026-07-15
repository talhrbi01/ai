import SwiftData
import SwiftUI

struct MediaDetailsView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.modelContext) private var modelContext
    @Query private var watchlistEntries: [WatchlistEntry]
    @State private var state: LoadState<MediaDetails> = .idle

    let media: MediaSummary

    var body: some View {
        MashhadBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero
                    actionBar
                    detailsContent
                }
            }
        }
        .navigationTitle(media.title)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: media.id) { await load() }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            PosterImage(path: media.backdropPath ?? media.posterPath, configuration: environment.configuration, contentMode: .fill)
                .frame(height: 230)
                .clipped()
                .overlay(LinearGradient(colors: [.clear, MashhadTheme.background], startPoint: .center, endPoint: .bottom))
            VStack(alignment: .leading, spacing: 6) {
                Text(media.title)
                    .font(.title.bold())
                    .foregroundStyle(MashhadTheme.textPrimary)
                HStack(spacing: 12) {
                    if let year = media.yearText { Text(year) }
                    Label(String(format: "%.1f", media.voteAverage), systemImage: "star.fill")
                        .foregroundStyle(MashhadTheme.warning)
                }
                .font(.subheadline)
                .foregroundStyle(MashhadTheme.textSecondary)
            }
            .padding(.horizontal, MashhadTheme.pagePadding)
            .padding(.bottom, 16)
        }
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button(action: toggleWatchlist) {
                Label(isInWatchlist ? "media_remove_watchlist" : "media_add_watchlist", systemImage: isInWatchlist ? "bookmark.slash" : "bookmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(MashhadTheme.accent)
            ShareLink(item: media.title) {
                Label("media_share", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
            .tint(MashhadTheme.accentSecondary)
        }
        .padding(.horizontal, MashhadTheme.pagePadding)
    }

    @ViewBuilder
    private var detailsContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            if !media.overview.isEmpty {
                Text(media.overview)
                    .font(.body)
                    .foregroundStyle(MashhadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            switch state {
            case .idle, .loading:
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, 24)
            case .failed(let message):
                ErrorStateView(message: message) { Task { await load() } }
            case .loaded(let details):
                if !details.summary.genreNames.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(details.summary.genreNames, id: \.self) { genre in
                                Text(genre)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(MashhadTheme.surface, in: Capsule())
                                    .foregroundStyle(MashhadTheme.accentSecondary)
                            }
                        }
                    }
                }
                if media.kind == .series, !details.seasons.isEmpty {
                    Text("media_seasons")
                        .font(.title3.bold())
                        .foregroundStyle(MashhadTheme.textPrimary)
                    ForEach(details.seasons) { season in
                        seasonRow(season)
                    }
                }
                if !details.cast.isEmpty {
                    Text("media_cast")
                        .font(.title3.bold())
                        .foregroundStyle(MashhadTheme.textPrimary)
                    ForEach(details.cast.prefix(8), id: \.id) { cast in
                        Text(cast.character.map { "\(cast.name) — \($0)" } ?? cast.name)
                            .font(.subheadline)
                            .foregroundStyle(MashhadTheme.textSecondary)
                    }
                }
            }
        }
        .padding(.horizontal, MashhadTheme.pagePadding)
        .padding(.bottom, 28)
    }

    private func seasonRow(_ season: SeasonSummary) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(season.name)
                    .font(.headline)
                    .foregroundStyle(MashhadTheme.textPrimary)
                Text("\(season.episodeCount) \(String(localized: "media_episodes"))")
                    .font(.caption)
                    .foregroundStyle(MashhadTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.forward")
                .foregroundStyle(MashhadTheme.textSecondary)
        }
        .padding()
        .background(MashhadTheme.surface, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }

    private var isInWatchlist: Bool {
        watchlistEntry != nil
    }

    private func toggleWatchlist() {
        if let existing = watchlistEntry {
            modelContext.delete(existing)
        } else {
            modelContext.insert(WatchlistEntry(media: media))
        }
    }

    private var watchlistEntry: WatchlistEntry? {
        let id = "\(media.kind.rawValue)-\(media.id)"
        return watchlistEntries.first { $0.id == id }
    }

    @MainActor
    private func load() async {
        state = .loading
        do { state = .loaded(try await environment.tmdbService.details(for: media)) }
        catch is CancellationError { state = .idle }
        catch { state = .failed(error.localizedDescription) }
    }
}
