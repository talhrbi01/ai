import SwiftUI

enum MashhadTheme {
    static let background = Color(red: 0.055, green: 0.063, blue: 0.094)
    static let surface = Color(red: 0.102, green: 0.118, blue: 0.169)
    static let surfaceElevated = Color(red: 0.145, green: 0.161, blue: 0.220)
    static let accent = Color(red: 0.988, green: 0.486, blue: 0.271)
    static let accentSecondary = Color(red: 0.420, green: 0.788, blue: 0.718)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.68)
    static let divider = Color.white.opacity(0.10)
    static let warning = Color(red: 0.98, green: 0.75, blue: 0.31)

    static let pagePadding: CGFloat = 20
    static let cardRadius: CGFloat = 18
}

struct MashhadBackground<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            MashhadTheme.background.ignoresSafeArea()
            content
        }
    }
}
