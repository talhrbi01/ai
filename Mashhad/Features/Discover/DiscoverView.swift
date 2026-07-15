import SwiftUI

struct DiscoverView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var state: LoadState<[MediaSummary]> = .idle

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        MashhadBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("discover_title")
                        .font(.largeTitle.bold())
                        .foregroundStyle(MashhadTheme.textPrimary)
                    Text("discover_message")
                        .font(.subheadline)
                        .foregroundStyle(MashhadTheme.textSecondary)
                    NavigationLink(destination: SearchView()) {
                        Label("discover_search_action", systemImage: "magnifyingglass")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(MashhadTheme.accent)
                    content
                }
                .padding(.horizontal, MashhadTheme.pagePadding)
                .padding(.vertical, 20)
            }
            .refreshable { await load() }
        }
        .navigationTitle("tab_discover")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: environment.configuration.tmdbAPIKey) { await load() }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity).padding(.vertical, 50)
        case .failed(let message):
            ErrorStateView(message: message) { Task { await load() } }
        case .loaded(let media):
            LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                ForEach(media) { item in
                    NavigationLink(value: AppRouter.Route.mediaDetails(item)) {
                        MediaPosterCard(media: item, configuration: environment.configuration)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @MainActor
    private func load() async {
        state = .loading
        do { state = .loaded(try await environment.tmdbService.trending()) }
        catch is CancellationError { state = .idle }
        catch { state = .failed(error.localizedDescription) }
    }
}
