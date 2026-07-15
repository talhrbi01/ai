import Foundation
import Observation

@MainActor
@Observable
final class SessionStore {
    private enum Keys {
        static let onboardingComplete = "onboarding.complete"
        static let authSession = "auth.session"
    }

    private let defaults: UserDefaults
    private let keychain: KeychainStore
    var isAuthenticated = false
    var isOnboardingComplete: Bool
    private(set) var authSession: AuthSession?

    init(defaults: UserDefaults = .standard, keychain: KeychainStore = KeychainStore()) {
        self.defaults = defaults
        self.keychain = keychain
        self.isOnboardingComplete = defaults.bool(forKey: Keys.onboardingComplete)
        self.authSession = nil
        let storedData: Data? = try? keychain.data(forKey: Keys.authSession)
        if let storedData,
           let session = try? JSONDecoder().decode(AuthSession.self, from: storedData) {
            self.authSession = session
            self.isAuthenticated = true
        }
    }

    func completeOnboarding() {
        isOnboardingComplete = true
        defaults.set(true, forKey: Keys.onboardingComplete)
    }

    func resetOnboarding() {
        isOnboardingComplete = false
        defaults.set(false, forKey: Keys.onboardingComplete)
    }

    func signOut() {
        isAuthenticated = false
        authSession = nil
        try? keychain.removeValue(forKey: Keys.authSession)
    }

    func setAuthenticated(_ session: AuthSession) {
        authSession = session
        isAuthenticated = true
        if let data = try? JSONEncoder().encode(session) {
            try? keychain.set(data, forKey: Keys.authSession)
        }
    }

    func completeAuthenticatedOnboarding() {
        isOnboardingComplete = true
        defaults.set(true, forKey: Keys.onboardingComplete)
    }
}
