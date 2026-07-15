import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
final class NotificationScheduler {
    private let center: UNUserNotificationCenter
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func refreshStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestAuthorization() async throws -> Bool {
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        await refreshStatus()
        return granted
    }

    func scheduleEpisodeReminder(id: String, title: String, date: Date) async throws {
        guard date > .now else { return }
        if authorizationStatus == .notDetermined {
            guard try await requestAuthorization() else { return }
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = String(localized: "notification_episode_body")
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try await center.add(request)
    }

    func cancelReminder(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }
}
