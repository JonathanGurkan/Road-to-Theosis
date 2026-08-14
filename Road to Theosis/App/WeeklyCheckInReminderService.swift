import Foundation
import UserNotifications

extension Notification.Name {
    static let weeklyCheckInNotificationTapped = Notification.Name("weeklyCheckInNotificationTapped")
    static let weeklyCheckInNotificationSnoozed = Notification.Name("weeklyCheckInNotificationSnoozed")
}

@MainActor
struct WeeklyCheckInReminderService {
    static let categoryIdentifier = "weekly-check-in"
    static let snoozeActionIdentifier = "weekly-check-in-snooze"
    private let notificationIdentifier = "weekly-check-in-reminder"
    private let snoozedNotificationIdentifier = "weekly-check-in-snoozed-reminder"
    private let snoozeDuration: TimeInterval = 2 * 60 * 60

    func notifyIfDue(preferences: AppPreferenceStore, now: Date = .now, calendar: Calendar = .current) async {
        guard preferences.isWeeklyCheckInReminderEnabled,
              now.timeIntervalSince1970 >= preferences.weeklyCheckInSnoozedUntil,
              isDue(now: now, preferences: preferences, calendar: calendar) else {
            return
        }

        let dayKey = Self.dayKey(for: now, calendar: calendar)
        guard preferences.lastWeeklyCheckInReminderDay != dayKey else {
            return
        }

        let isAuthorized = await requestNotificationAuthorization()
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time for a check-in"
        content.body = "Take a few minutes to recalibrate your weekly check-in."
        content.sound = .default
        content.categoryIdentifier = Self.categoryIdentifier
        content.userInfo = ["route": "weeklyCheckIn"]

        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            preferences.lastWeeklyCheckInReminderDay = dayKey
        } catch {
            return
        }
    }

    func snooze(preferences: AppPreferenceStore, now: Date = .now) async {
        guard await requestNotificationAuthorization() else { return }

        let snoozedUntil = now.addingTimeInterval(snoozeDuration)
        preferences.weeklyCheckInSnoozedUntil = snoozedUntil.timeIntervalSince1970

        let content = UNMutableNotificationContent()
        content.title = "Time for a check-in"
        content.body = "Your check-in reminder is ready again."
        content.sound = .default
        content.categoryIdentifier = Self.categoryIdentifier
        content.userInfo = ["route": "weeklyCheckIn"]

        let request = UNNotificationRequest(
            identifier: snoozedNotificationIdentifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: snoozeDuration, repeats: false)
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    private func isDue(now: Date, preferences: AppPreferenceStore, calendar: Calendar) -> Bool {
        let components = calendar.dateComponents([.weekday, .hour, .minute], from: now)
        guard components.weekday == preferences.weeklyCheckInWeekday.rawValue else {
            return false
        }

        let currentMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        let targetMinutes = preferences.weeklyCheckInHour * 60 + preferences.weeklyCheckInMinute
        return currentMinutes >= targetMinutes
    }

    private func requestNotificationAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    private static func dayKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return [components.year, components.month, components.day]
            .compactMap { $0 }
            .map(String.init)
            .joined(separator: "-")
    }
}
