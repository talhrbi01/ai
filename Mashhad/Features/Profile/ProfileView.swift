import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(AppEnvironment.self) private var environment
    @Query(sort: \WatchlistEntry.createdAt, order: .reverse) private var entries: [WatchlistEntry]

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
                    Button("profile_sign_out") {
                        environment.session.signOut()
                        environment.session.resetOnboarding()
                    }
                    .foregroundStyle(MashhadTheme.textSecondary)
                }
                .padding(.horizontal, MashhadTheme.pagePadding)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("tab_profile")
        .navigationBarTitleDisplayMode(.inline)
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
}
