import Foundation
import Observation

@MainActor
@Observable
final class SessionStore {
    private enum Keys {
        static let onboardingComplete = "onboarding.complete"
    }

    private let defaults: UserDefaults
    var isAuthenticated = false
    var isOnboardingComplete: Bool

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isOnboardingComplete = defaults.bool(forKey: Keys.onboardingComplete)
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
    }
}
