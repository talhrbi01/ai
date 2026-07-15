import Observation

@MainActor
@Observable
final class AppEnvironment {
    let configuration: AppConfiguration
    let tmdbService: any TMDBServiceProtocol
    let supabaseService: any SupabaseServiceProtocol
    let authenticationService: any AuthenticationServiceProtocol
    let syncQueue: OfflineSyncQueue
    let notifications: NotificationScheduler
    let router: AppRouter
    let session: SessionStore

    init(
        configuration: AppConfiguration,
        tmdbService: any TMDBServiceProtocol,
        supabaseService: any SupabaseServiceProtocol,
        authenticationService: any AuthenticationServiceProtocol,
        syncQueue: OfflineSyncQueue = OfflineSyncQueue(),
        notifications: NotificationScheduler = NotificationScheduler(),
        router: AppRouter = AppRouter(),
        session: SessionStore = SessionStore()
    ) {
        self.configuration = configuration
        self.tmdbService = tmdbService
        self.supabaseService = supabaseService
        self.authenticationService = authenticationService
        self.syncQueue = syncQueue
        self.notifications = notifications
        self.router = router
        self.session = session
    }
}
