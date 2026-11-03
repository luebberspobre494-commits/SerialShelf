import Foundation
import UserNotifications

/// Local reminders only — no push, no server. One notification per item, set
/// 30 days before the warranty ends.
enum Reminders {
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    static func reschedule(for item: GearItem) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }

        let identifier = "warranty-\(item.persistentModelID.hashValue)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let fireDate = Calendar.current.date(byAdding: .day, value: -30, to: item.warrantyEnd) ?? item.warrantyEnd
        guard fireDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(item.name) 的保修快到期了"
        content.body = "还剩 30 天。需要维修或延保的话，现在就该联系。"
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    static func remove(for item: GearItem) {
        let identifier = "warranty-\(item.persistentModelID.hashValue)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
