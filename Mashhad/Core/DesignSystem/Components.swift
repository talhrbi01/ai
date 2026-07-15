import SwiftUI

struct PosterImage: View {
    let path: String?
    let configuration: AppConfiguration
    var contentMode: ContentMode = .fill

    var body: some View {
        AsyncImage(url: configuration.imageURL(path: path)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: contentMode)
            case .failure, .empty:
                ZStack {
                    MashhadTheme.surfaceElevated
                    Image(systemName: "film").font(.title2).foregroundStyle(MashhadTheme.textSecondary)
                }
            @unknown default:
                Color.clear
            }
        }
        .accessibilityHidden(true)
    }
}

struct MediaPosterCard: View {
    let media: MediaSummary
    let configuration: AppConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PosterImage(path: media.posterPath, configuration: configuration)
                .frame(width: 130, height: 190)
                .clipShape(RoundedRectangle(cornerRadius: MashhadTheme.cardRadius))
                .overlay(alignment: .topTrailing) {
                    if media.voteAverage > 0 {
                        Label(String(format: "%.1f", media.voteAverage), systemImage: "star.fill")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 5)
                            .background(.black.opacity(0.72), in: Capsule())
                            .foregroundStyle(MashhadTheme.warning)
                            .padding(8)
                    }
                }
            Text(media.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MashhadTheme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: 130, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(media.title))
    }
}

struct SectionHeader: View {
    let title: LocalizedStringKey
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(MashhadTheme.textPrimary)
            Spacer()
            if let action {
                Button("common_see_all", action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MashhadTheme.accent)
            }
        }
    }
}

struct EmptyStateView: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    var symbol: String = "tray"
    var actionTitle: LocalizedStringKey? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(MashhadTheme.accentSecondary)
            Text(title)
                .font(.headline)
                .foregroundStyle(MashhadTheme.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(MashhadTheme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(MashhadTheme.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
        .accessibilityElement(children: .combine)
    }
}

struct ErrorStateView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        EmptyStateView(
            title: "common_something_went_wrong",
            message: LocalizedStringKey(message),
            symbol: "wifi.exclamationmark",
            actionTitle: "common_retry",
            action: retry
        )
    }
}

struct SpoilerBlurView<Content: View>: View {
    let isHidden: Bool
    let content: Content
    @State private var isRevealed = false

    init(isHidden: Bool, @ViewBuilder content: () -> Content) {
        self.isHidden = isHidden
        self.content = content()
    }

    var body: some View {
        ZStack {
            content
                .blur(radius: isHidden && !isRevealed ? 13 : 0)
            if isHidden && !isRevealed {
                Button("spoiler_reveal") { isRevealed = true }
                    .buttonStyle(.borderedProminent)
                    .tint(MashhadTheme.accent)
                    .accessibilityHint(Text("spoiler_reveal_hint"))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isRevealed)
    }
}
