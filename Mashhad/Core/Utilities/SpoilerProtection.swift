import Foundation

struct EpisodeCoordinate: Hashable, Codable, Sendable {
    let season: Int
    let episode: Int
}

enum SpoilerProtection {
    static func shouldHide(
        spoilerAt location: EpisodeCoordinate?,
        watchedThrough: EpisodeCoordinate?,
        explicitlyRevealed: Bool
    ) -> Bool {
        guard !explicitlyRevealed, let location else { return false }
        guard let watchedThrough else { return true }
        if location.season != watchedThrough.season {
            return location.season > watchedThrough.season
        }
        return location.episode > watchedThrough.episode
    }
}
