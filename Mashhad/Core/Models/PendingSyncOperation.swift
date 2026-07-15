import Foundation
import SwiftData

enum SyncOperationKind: String, Codable, Sendable {
    case addWatchlist
    case removeWatchlist
    case markEpisodeWatched
    case removeEpisodeWatched
}

struct EpisodeSyncPayload: Codable, Sendable {
    let mediaID: Int
    let seasonNumber: Int
    let episodeNumber: Int
}

@Model
final class PendingSyncOperation {
    @Attribute(.unique) var id: UUID
    var kindRaw: String
    var payload: Data
    var createdAt: Date
    var attemptCount: Int
    var lastError: String?

    init(kind: SyncOperationKind, payload: Data, createdAt: Date = .now) {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.payload = payload
        self.createdAt = createdAt
        self.attemptCount = 0
    }

    var kind: SyncOperationKind? { SyncOperationKind(rawValue: kindRaw) }
}
