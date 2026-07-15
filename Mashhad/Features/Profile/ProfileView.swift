import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(AppEnvironment.self) private var environment
    @Query(sort: \WatchlistEntry.createdAt, order: .reverse) private var entries: [WatchlistEntry]
    @State private var showDeleteConfirmation = false
    @State private var profileError: String?
    @State private var notificationMessage: String?

    var body: some View {
        MashhadBackground {
            ScrollView {
                VStack(spacing: 18) {
                    profileHeader
                    HStack(spacing: 12) {
                        statCard(value: entries.count, title: "profile_watchlist")
                        statCard(value: entries.filter { $0.kindRaw == MediaKind.series.rawValue }.count, title: "profile_series")
                    }
                    NavigationLink(destination: WatchlistView()) {
                        Label("profile_open_watchlist", systemImage: "bookmark.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(MashhadTheme.accent)
                    NavigationLink(destination: StatisticsView()) {
                        Label("profile_open_statistics", systemImage: "chart.bar.xaxis")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(MashhadTheme.accentSecondary)
                    NavigationLink(destination: ListsView()) {
                        Label("profile_open_lists", systemImage: "square.stack.3d.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(MashhadTheme.accentSecondary)
                    Button {
                        Task { await requestNotifications() }
                    } label: {
                        Label("profile_enable_notifications", systemImage: "bell.badge")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(MashhadTheme.accentSecondary)
                    if let notificationMessage {
                        Text(notificationMessage)
                            .font(.footnote)
                            .foregroundStyle(MashhadTheme.textSecondary)
                    }
                    if environment.session.isAuthenticated {
                        Button("profile_sign_out") {
                            Task { await signOut() }
                        }
                        .foregroundStyle(MashhadTheme.textSecondary)
                        Button("profile_delete_account", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                    } else {
                        NavigationLink(destination: AuthenticationView()) {
                            Label("profile_sign_in", systemImage: "person.badge.key")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(MashhadTheme.accentSecondary)
                    }
                    if let profileError {
                        Text(profileError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, MashhadTheme.pagePadding)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("tab_profile")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("profile_delete_account_title", isPresented: $showDeleteConfirmation) {
            Button("profile_delete_account_confirm", role: .destructive) {
                Task { await deleteAccount() }
            }
            Button("common_cancel", role: .cancel) { }
        } message: {
            Text("profile_delete_account_message")
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 78))
                .foregroundStyle(MashhadTheme.accentSecondary)
            Text("profile_guest_name")
                .font(.title2.bold())
                .foregroundStyle(MashhadTheme.textPrimary)
            Text("profile_guest_message")
                .font(.subheadline)
                .foregroundStyle(MashhadTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private func statCard(value: Int, title: LocalizedStringKey) -> some View {
        VStack(spacing: 6) {
            Text(value, format: .number)
                .font(.title.bold())
                .foregroundStyle(MashhadTheme.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundStyle(MashhadTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(MashhadTheme.surface, in: RoundedRectangle(cornerRadius: MashhadTheme.cardRadius))
    }

    @MainActor
    private func signOut() async {
        guard let session = environment.session.authSession else {
            environment.session.signOut()
            return
        }
        do {
            try await environment.authenticationService.signOut(accessToken: session.accessToken)
        } catch {
            profileError = error.localizedDescription
        }
        environment.session.signOut()
    }

    @MainActor
    private func deleteAccount() async {
        guard let session = environment.session.authSession else { return }
        do {
            try await environment.authenticationService.deleteAccount(accessToken: session.accessToken)
            environment.session.signOut()
            environment.session.resetOnboarding()
        } catch {
            profileError = error.localizedDescription
        }
    }

    @MainActor
    private func requestNotifications() async {
        do {
            let granted = try await environment.notifications.requestAuthorization()
            notificationMessage = String(localized: granted ? "notifications_enabled" : "notifications_denied")
        } catch {
            notificationMessage = error.localizedDescription
        }
    }
}
