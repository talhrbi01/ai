import SwiftUI
import Observation

@MainActor
@Observable
final class AppRouter {
    enum Route: Hashable {
        case mediaDetails(MediaSummary)
    }

    var selectedTab: AppTab = .home
    private var tabPaths: [AppTab: [Route]] = Dictionary(uniqueKeysWithValues: AppTab.allCases.map { ($0, []) })

    func path(for tab: AppTab) -> [Route] { tabPaths[tab] ?? [] }

    func setPath(_ path: [Route], for tab: AppTab) {
        tabPaths[tab] = path
    }

    func binding(for tab: AppTab) -> Binding<[Route]> {
        Binding(
            get: { [weak self] in self?.path(for: tab) ?? [] },
            set: { [weak self] newPath in self?.setPath(newPath, for: tab) }
        )
    }

    func open(_ route: Route, on tab: AppTab? = nil) {
        let destinationTab = tab ?? selectedTab
        selectedTab = destinationTab
        tabPaths[destinationTab, default: []].append(route)
    }
}
