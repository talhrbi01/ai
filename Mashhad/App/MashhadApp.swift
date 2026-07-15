import SwiftData
import SwiftUI

@main
struct MashhadApp: App {
    @State private var environment: AppEnvironment
    private let modelContainer: ModelContainer

    init() {
        let configuration = AppConfiguration.fromBundle()
        let tmdbService = TMDBService(apiKey: configuration.tmdbAPIKey)
        let supabaseService = SupabaseService(baseURL: configuration.supabaseURL, anonKey: configuration.supabaseAnonKey)
        let authenticationService = SupabaseAuthenticationService(baseURL: configuration.supabaseURL, anonKey: configuration.supabaseAnonKey)
        _environment = State(initialValue: AppEnvironment(configuration: configuration, tmdbService: tmdbService, supabaseService: supabaseService, authenticationService: authenticationService))
        modelContainer = Self.makeModelContainer()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .modelContainer(modelContainer)
        }
    }

    private static func makeModelContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: WatchlistEntry.self, EpisodeProgress.self, PendingSyncOperation.self)
        } catch {
            fatalError("Unable to create the local data store: \(error.localizedDescription)")
        }
    }
}

@MainActor
struct RootView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        Group {
            if environment.session.isOnboardingComplete {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(MashhadTheme.accent)
    }
}

@MainActor
struct MainTabView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        TabView(selection: Binding(
            get: { environment.router.selectedTab },
            set: { environment.router.selectedTab = $0 }
        )) {
            tab(.home) { HomeView() }
            tab(.discover) { DiscoverView() }
            tab(.calendar) { CalendarView() }
            tab(.activity) { ActivityView() }
            tab(.profile) { ProfileView() }
        }
    }

    @ViewBuilder
    private func tab<Content: View>(_ tab: AppTab, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack(path: environment.router.binding(for: tab)) {
            content()
                .navigationDestination(for: AppRouter.Route.self) { route in
                    switch route {
                    case .mediaDetails(let media):
                        MediaDetailsView(media: media)
                    }
                }
        }
        .tabItem { Label(tab.titleKey, systemImage: tab.symbol) }
        .tag(tab)
    }
}
