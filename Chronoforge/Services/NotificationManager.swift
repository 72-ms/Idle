import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("[NotificationManager] Permission error: \(error)")
            }
        }
    }

    func scheduleOfflineEarningsNotification(afterHours: Int = 4) {
        let content = UNMutableNotificationContent()
        content.title = "Chronoforge"
        content.body = "Your Temporal Energy bank is filling up! Come back to collect."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(afterHours * 3600),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "offline_earnings",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleDailyReminderNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Chronoforge"
        content.body = "Your daily reward is ready! Don't break your streak."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 10 // 10 AM
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "daily_reward",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func rescheduleNotifications() {
        cancelAllNotifications()
        scheduleOfflineEarningsNotification()
        scheduleDailyReminderNotification()
    }
}
