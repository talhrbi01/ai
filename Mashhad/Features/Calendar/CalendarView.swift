import SwiftUI

struct CalendarView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        MashhadBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("calendar_title")
                        .font(.largeTitle.bold())
                        .foregroundStyle(MashhadTheme.textPrimary)
                    Text("calendar_message")
                        .font(.subheadline)
                        .foregroundStyle(MashhadTheme.textSecondary)
                    EmptyStateView(
                        title: "calendar_empty_title",
                        message: "calendar_empty_message",
                        symbol: "calendar.badge.clock",
                        actionTitle: "discover_search_action"
                    ) {
                        environment.router.selectedTab = .discover
                    }
                }
                .padding(.horizontal, MashhadTheme.pagePadding)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("tab_calendar")
        .navigationBarTitleDisplayMode(.inline)
    }
}
