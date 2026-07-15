import SwiftData
import SwiftUI

struct MediaDetailsView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.modelContext) private var modelContext
    @Query private var watchlistEntries: [WatchlistEntry]
    @State private var selectedSeason: SeasonSummary?
    @State private var showListPicker = false
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
        .sheet(item: $selectedSeason) { season in
            NavigationStack {
                EpisodeListView(media: media, season: season)
            }
        }
        .sheet(isPresented: $showListPicker) {
            NavigationStack {
                ListPickerView(media: media)
            }
        }
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
            Button {
                showListPicker = true
            } label: {
                Label("media_add_to_list", systemImage: "square.stack.3d.up")
            }
            .buttonStyle(.bordered)
            .tint(MashhadTheme.accentSecondary)
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
        Button { selectedSeason = season } label: {
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
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private var isInWatchlist: Bool {
        watchlistEntry != nil
    }

    private func toggleWatchlist() {
        if let existing = watchlistEntry {
            modelContext.delete(existing)
            environment.syncQueue.enqueue(
                kind: .removeWatchlist,
                payload: WatchlistSyncPayload(mediaID: media.id, mediaKind: media.kind, title: media.title),
                in: modelContext
            )
        } else {
            modelContext.insert(WatchlistEntry(media: media))
            environment.syncQueue.enqueue(
                kind: .addWatchlist,
                payload: WatchlistSyncPayload(mediaID: media.id, mediaKind: media.kind, title: media.title),
                in: modelContext
            )
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

struct EpisodeListView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.modelContext) private var modelContext
    @Query private var progressEntries: [EpisodeProgress]
    @State private var state: LoadState<[EpisodeSummary]> = .idle

    let media: MediaSummary
    let season: SeasonSummary

    var body: some View {
        MashhadBackground {
            Group {
                switch state {
                case .idle, .loading:
                    ProgressView().frame(maxWidth: .infinity)
                case .failed(let message):
                    ErrorStateView(message: message) { Task { await load() } }
                case .loaded(let episodes):
                    if episodes.isEmpty {
                        EmptyStateView(title: "episodes_empty_title", message: "episodes_empty_message", symbol: "rectangle.stack")
                    } else {
                        List(episodes) { episode in
                            episodeRow(episode)
                                .listRowBackground(MashhadTheme.surface)
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
        }
        .navigationTitle(season.name)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: "\(media.id)-\(season.seasonNumber)") { await load() }
    }

    private func episodeRow(_ episode: EpisodeSummary) -> some View {
        Button { toggle(episode) } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isWatched(episode) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isWatched(episode) ? MashhadTheme.accent : MashhadTheme.textSecondary)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(episode.episodeNumber). \(episode.name)")
                        .font(.headline)
                        .foregroundStyle(MashhadTheme.textPrimary)
                    if let airDateText = episode.airDateText {
                        Text(airDateText)
                            .font(.caption)
                            .foregroundStyle(MashhadTheme.textSecondary)
                    }
                    if !episode.overview.isEmpty {
                        SpoilerBlurView(isHidden: !isWatched(episode)) {
                            Text(episode.overview)
                                .font(.subheadline)
                                .foregroundStyle(MashhadTheme.textSecondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .accessibilityValue(Text(LocalizedStringKey(isWatched(episode) ? "episode_watched" : "episode_unwatched")))
    }

    private func isWatched(_ episode: EpisodeSummary) -> Bool {
        progressEntries.contains { $0.id == progressID(for: episode) && $0.isWatched }
    }

    private func progressID(for episode: EpisodeSummary) -> String {
        "\(media.id)-s\(episode.seasonNumber)-e\(episode.episodeNumber)"
    }

    private func toggle(_ episode: EpisodeSummary) {
        if let existing = progressEntries.first(where: { $0.id == progressID(for: episode) }) {
            modelContext.delete(existing)
            environment.syncQueue.enqueue(
                kind: .removeEpisodeWatched,
                payload: EpisodeSyncPayload(mediaID: media.id, seasonNumber: episode.seasonNumber, episodeNumber: episode.episodeNumber),
                in: modelContext
            )
        } else {
            modelContext.insert(EpisodeProgress(mediaID: media.id, seasonNumber: episode.seasonNumber, episodeNumber: episode.episodeNumber, watchedAt: .now))
            environment.syncQueue.enqueue(
                kind: .markEpisodeWatched,
                payload: EpisodeSyncPayload(mediaID: media.id, seasonNumber: episode.seasonNumber, episodeNumber: episode.episodeNumber),
                in: modelContext
            )
        }
    }

    @MainActor
    private func load() async {
        state = .loading
        do { state = .loaded(try await environment.tmdbService.episodes(for: media, seasonNumber: season.seasonNumber)) }
        catch is CancellationError { state = .idle }
        catch { state = .failed(error.localizedDescription) }
    }
}
