import Foundation
import Observation
import SwiftData

protocol OfflineSyncSender: Sendable {
    func send(kind: SyncOperationKind, payload: Data) async throws
}

@MainActor
@Observable
final class OfflineSyncQueue {
    var isSyncing = false

    func enqueue<T: Encodable>(kind: SyncOperationKind, payload: T, in context: ModelContext) {
        guard let data = try? JSONEncoder().encode(payload) else { return }
        context.insert(PendingSyncOperation(kind: kind, payload: data))
        try? context.save()
    }

    func drain(in context: ModelContext, sender: any OfflineSyncSender) async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        let descriptor = FetchDescriptor<PendingSyncOperation>(sortBy: [SortDescriptor<PendingSyncOperation>(\.createdAt)])
        guard let operations = try? context.fetch(descriptor) else { return }
        for operation in operations {
            guard let kind = operation.kind else {
                context.delete(operation)
                continue
            }
            do {
                try await sender.send(kind: kind, payload: operation.payload)
                context.delete(operation)
            } catch {
                operation.attemptCount += 1
                operation.lastError = error.localizedDescription
            }
        }
        try? context.save()
    }
}

struct WatchlistSyncPayload: Codable, Sendable {
    let mediaID: Int
    let mediaKind: MediaKind
    let title: String
}
