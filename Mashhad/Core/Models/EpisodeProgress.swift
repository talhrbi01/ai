import Foundation
import SwiftData

@Model
final class EpisodeProgress {
    @Attribute(.unique) var id: String
    var mediaID: Int
    var seasonNumber: Int
    var episodeNumber: Int
    var watchedAt: Date?
    var updatedAt: Date

    init(mediaID: Int, seasonNumber: Int, episodeNumber: Int, watchedAt: Date? = nil) {
        self.id = "\(mediaID)-s\(seasonNumber)-e\(episodeNumber)"
        self.mediaID = mediaID
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.watchedAt = watchedAt
        self.updatedAt = .now
    }

    var isWatched: Bool { watchedAt != nil }
}
