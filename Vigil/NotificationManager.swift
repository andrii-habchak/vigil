import Foundation
import UserNotifications

/// Thin wrapper around `UNUserNotificationCenter` for Vigil's opt-in notifications
/// (session end, low-battery pause, resume). Best-effort: if authorization is denied
/// or unavailable, posts silently no-op.
final class NotificationManager {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func post(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)
        center.add(request, withCompletionHandler: nil)
    }
}
