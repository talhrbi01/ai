import SwiftUI

struct OnboardingView: View {
    @Environment(AppEnvironment.self) private var environment
    @AppStorage("preferredLanguage") private var preferredLanguage = "ar"
    @AppStorage("preferredCountry") private var preferredCountry = "SA"
    @State private var page = 0

    private let pages: [(title: LocalizedStringKey, message: LocalizedStringKey, symbol: String)] = [
        ("onboarding_welcome_title", "onboarding_welcome_message", "sparkles.tv"),
        ("onboarding_preferences_title", "onboarding_preferences_message", "slider.horizontal.3"),
        ("onboarding_ready_title", "onboarding_ready_message", "checkmark.seal.fill")
    ]

    var body: some View {
        MashhadBackground {
            VStack(spacing: 28) {
                Spacer()
                Image(systemName: pages[page].symbol)
                    .font(.system(size: 76, weight: .medium))
                    .foregroundStyle(MashhadTheme.accent)
                    .symbolRenderingMode(.hierarchical)
                Text(pages[page].title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(MashhadTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Text(pages[page].message)
                    .font(.body)
                    .foregroundStyle(MashhadTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 26)

                if page == 1 {
                    preferences
                }

                Spacer()
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? MashhadTheme.accent : MashhadTheme.divider)
                            .frame(width: index == page ? 28 : 8, height: 8)
                    }
                }
                Button(page == pages.count - 1 ? "onboarding_start" : "common_continue") {
                    if page == pages.count - 1 {
                        environment.session.completeOnboarding()
                    } else {
                        withAnimation(.easeInOut) { page += 1 }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(MashhadTheme.accent)
                .controlSize(.large)
                .padding(.bottom, 12)
            }
            .padding(.horizontal, MashhadTheme.pagePadding)
            .environment(\.layoutDirection, preferredLanguage == "ar" ? .rightToLeft : .leftToRight)
        }
    }

    private var preferences: some View {
        VStack(spacing: 14) {
            Picker("onboarding_language", selection: $preferredLanguage) {
                Text("language_arabic").tag("ar")
                Text("language_english").tag("en")
            }
            .pickerStyle(.segmented)

            Picker("onboarding_country", selection: $preferredCountry) {
                Text("country_saudi_arabia").tag("SA")
                Text("country_uae").tag("AE")
                Text("country_kuwait").tag("KW")
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(MashhadTheme.surface, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
