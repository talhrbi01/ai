import Foundation
import SwiftData

enum CustomListVisibility: String, Codable, CaseIterable, Hashable, Sendable {
    case `private`
    case publicList = "public"
    case unlisted
}

struct ListItemSnapshot: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let mediaID: Int
    let kind: MediaKind
    let title: String
    let posterPath: String?

    init(media: MediaSummary) {
        self.id = "\(media.kind.rawValue)-\(media.id)"
        self.mediaID = media.id
        self.kind = media.kind
        self.title = media.title
        self.posterPath = media.posterPath
    }
}

@Model
final class CustomList {
    @Attribute(.unique) var id: UUID
    var title: String
    var listDescription: String
    var visibilityRaw: String
    var itemsData: Data
    var createdAt: Date
    var updatedAt: Date

    init(title: String, description: String = "", visibility: CustomListVisibility = .private) {
        self.id = UUID()
        self.title = title
        self.listDescription = description
        self.visibilityRaw = visibility.rawValue
        self.itemsData = Data()
        self.createdAt = .now
        self.updatedAt = .now
    }

    var visibility: CustomListVisibility {
        get { CustomListVisibility(rawValue: visibilityRaw) ?? .private }
        set { visibilityRaw = newValue.rawValue; updatedAt = .now }
    }

    var items: [ListItemSnapshot] {
        get { (try? JSONDecoder().decode([ListItemSnapshot].self, from: itemsData)) ?? [] }
        set {
            itemsData = (try? JSONEncoder().encode(newValue)) ?? Data()
            updatedAt = .now
        }
    }

    func add(media: MediaSummary) {
        guard !items.contains(where: { $0.id == "\(media.kind.rawValue)-\(media.id)" }) else { return }
        var updatedItems = items
        updatedItems.append(ListItemSnapshot(media: media))
        items = updatedItems
    }
}
