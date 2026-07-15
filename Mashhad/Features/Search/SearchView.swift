import SwiftUI

struct SearchView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var query = ""
    @State private var state: LoadState<[MediaSummary]> = .idle

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        MashhadBackground {
            ScrollView {
                content
                    .padding(.horizontal, MashhadTheme.pagePadding)
                    .padding(.vertical, 20)
            }
        }
        .navigationTitle("search_title")
        .searchable(text: $query, prompt: "search_prompt")
        .task(id: query) { await search() }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .idle:
            EmptyStateView(title: "search_empty_title", message: "search_empty_message", symbol: "magnifyingglass")
        case .loading:
            ProgressView().frame(maxWidth: .infinity).padding(.vertical, 80)
        case .failed(let message):
            ErrorStateView(message: message) { Task { await search() } }
        case .loaded(let results):
            if results.isEmpty {
                EmptyStateView(title: "search_no_results_title", message: "search_no_results_message", symbol: "questionmark.folder")
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                    ForEach(results) { item in
                        NavigationLink(value: AppRouter.Route.mediaDetails(item)) {
                            MediaPosterCard(media: item, configuration: environment.configuration)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @MainActor
    private func search() async {
        do { try await Task.sleep(nanoseconds: 350_000_000) }
        catch { return }
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            state = .idle
            return
        }
        state = .loading
        do { state = .loaded(try await environment.tmdbService.search(query: trimmedQuery)) }
        catch is CancellationError { state = .idle }
        catch { state = .failed(error.localizedDescription) }
    }
}
