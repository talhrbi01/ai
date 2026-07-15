import Foundation

struct WatchProgress: Equatable, Sendable {
    let watchedEpisodes: Int
    let totalEpisodes: Int

    var fraction: Double {
        guard totalEpisodes > 0 else { return 0 }
        return min(max(Double(watchedEpisodes) / Double(totalEpisodes), 0), 1)
    }
}

enum WatchProgressCalculator {
    static func progress<C: Collection>(totalEpisodes: Int, watchedEpisodeNumbers: C) -> WatchProgress where C.Element == Int {
        let validWatched = Set(watchedEpisodeNumbers).filter { $0 > 0 && $0 <= totalEpisodes }.count
        return WatchProgress(watchedEpisodes: validWatched, totalEpisodes: max(totalEpisodes, 0))
    }

    static func nextUnwatchedEpisode<C: Collection>(totalEpisodes: Int, watchedEpisodeNumbers: C) -> Int? where C.Element == Int {
        guard totalEpisodes > 0 else { return nil }
        let watched = Set(watchedEpisodeNumbers)
        return (1...totalEpisodes).first { !watched.contains($0) }
    }
}
