import SwiftData
import SwiftUI

struct StatisticsView: View {
    @Query private var entries: [WatchlistEntry]

    var body: some View {
        MashhadBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("statistics_title")
                        .font(.largeTitle.bold())
                        .foregroundStyle(MashhadTheme.textPrimary)
                    Text("statistics_message")
                        .font(.subheadline)
                        .foregroundStyle(MashhadTheme.textSecondary)
                    HStack(spacing: 12) {
                        metric(value: entries.count, title: "statistics_saved")
                        metric(value: entries.filter { $0.status == .completed }.count, title: "statistics_completed")
                    }
                    EmptyStateView(
                        title: "statistics_more_title",
                        message: "statistics_more_message",
                        symbol: "chart.xyaxis.line"
                    )
                }
                .padding(.horizontal, MashhadTheme.pagePadding)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("statistics_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func metric(value: Int, title: LocalizedStringKey) -> some View {
        VStack(spacing: 5) {
            Text(value, format: .number)
                .font(.title.bold())
            Text(title).font(.caption).foregroundStyle(MashhadTheme.textSecondary)
        }
        .foregroundStyle(MashhadTheme.textPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(MashhadTheme.surface, in: RoundedRectangle(cornerRadius: MashhadTheme.cardRadius))
    }
}
