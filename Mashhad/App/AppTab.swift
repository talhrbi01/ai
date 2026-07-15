import SwiftUI

enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home
    case discover
    case calendar
    case activity
    case profile

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .home: return "tab_home"
        case .discover: return "tab_discover"
        case .calendar: return "tab_calendar"
        case .activity: return "tab_activity"
        case .profile: return "tab_profile"
        }
    }

    var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .discover: return "sparkles"
        case .calendar: return "calendar"
        case .activity: return "person.2.wave.2"
        case .profile: return "person.crop.circle"
        }
    }
}
