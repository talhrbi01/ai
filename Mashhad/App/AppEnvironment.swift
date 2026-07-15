import Observation

@MainActor
@Observable
final class AppEnvironment {
    let configuration: AppConfiguration
    let tmdbService: any TMDBServiceProtocol
    let supabaseService: any SupabaseServiceProtocol
    let router: AppRouter
    let session: SessionStore

    init(
        configuration: AppConfiguration,
        tmdbService: any TMDBServiceProtocol,
        supabaseService: any SupabaseServiceProtocol,
        router: AppRouter = AppRouter(),
        session: SessionStore = SessionStore()
    ) {
        self.configuration = configuration
        self.tmdbService = tmdbService
        self.supabaseService = supabaseService
        self.router = router
        self.session = session
    }
}
