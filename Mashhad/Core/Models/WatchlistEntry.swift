import Foundation
import SwiftData

@Model
final class WatchlistEntry {
    @Attribute(.unique) var id: String
    var mediaID: Int
    var kindRaw: String
    var title: String
    var posterPath: String?
    var statusRaw: String
    var createdAt: Date

    init(media: MediaSummary, status: WatchStatus = .planToWatch) {
        self.id = "\(media.kind.rawValue)-\(media.id)"
        self.mediaID = media.id
        self.kindRaw = media.kind.rawValue
        self.title = media.title
        self.posterPath = media.posterPath
        self.statusRaw = status.rawValue
        self.createdAt = .now
    }

    var status: WatchStatus {
        get { WatchStatus(rawValue: statusRaw) ?? .planToWatch }
        set { statusRaw = newValue.rawValue }
    }
}
