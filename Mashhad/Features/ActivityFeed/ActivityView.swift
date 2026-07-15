import SwiftUI

struct ActivityView: View {
    var body: some View {
        MashhadBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("activity_title")
                        .font(.largeTitle.bold())
                        .foregroundStyle(MashhadTheme.textPrimary)
                    EmptyStateView(
                        title: "activity_empty_title",
                        message: "activity_empty_message",
                        symbol: "person.2.wave.2"
                    )
                }
                .padding(.horizontal, MashhadTheme.pagePadding)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("tab_activity")
        .navigationBarTitleDisplayMode(.inline)
    }
}
