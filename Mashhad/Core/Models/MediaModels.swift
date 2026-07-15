import Foundation

enum MediaKind: String, Codable, Hashable, Sendable {
    case movie
    case series
}

enum WatchStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case planToWatch
    case watching
    case completed
    case onHold
    case dropped
    case rewatching

    var titleKey: String {
        switch self {
        case .planToWatch: return "status_plan_to_watch"
        case .watching: return "status_watching"
        case .completed: return "status_completed"
        case .onHold: return "status_on_hold"
        case .dropped: return "status_dropped"
        case .rewatching: return "status_rewatching"
        }
    }
}

struct MediaSummary: Identifiable, Codable, Hashable, Sendable {
    let id: Int
    let kind: MediaKind
    let title: String
    let originalTitle: String?
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: Date?
    let voteAverage: Double
    let genreNames: [String]
    let numberOfSeasons: Int?

    var yearText: String? {
        releaseDate.map { String(Calendar.current.component(.year, from: $0)) }
    }
}

struct MediaDetails: Hashable, Sendable {
    let summary: MediaSummary
    let cast: [CastMember]
    let seasons: [SeasonSummary]
}

struct CastMember: Hashable, Sendable {
    let id: Int
    let name: String
    let character: String?
    let profilePath: String?
}

struct SeasonSummary: Identifiable, Hashable, Sendable {
    let id: Int
    let seasonNumber: Int
    let name: String
    let episodeCount: Int
}
