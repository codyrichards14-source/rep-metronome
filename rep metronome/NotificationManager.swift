import Combine
import Foundation
import UserNotifications

@MainActor
final class NotificationManager: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            await refreshAuthorizationStatus()
            return false
        }
    }

    func scheduleReminders(settings: ReminderSettings) async throws {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["cath-reminder"])

        guard settings.notificationsEnabled else { return }

        let seconds = max(settings.intervalHours * 3600, 60)
        let content = UNMutableNotificationContent()
        content.title = "Time to self cath"
        content.body = "Your personalized catheterization reminder is due."
        content.sound = settings.alarmSoundEnabled ? .default : nil

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: true)
        let request = UNNotificationRequest(identifier: "cath-reminder", content: content, trigger: trigger)
        try await center.add(request)
    }
}
