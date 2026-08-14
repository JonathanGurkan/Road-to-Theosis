import SwiftData
import SwiftUI
import UIKit
import UserNotifications

final class AppNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let snoozeAction = UNNotificationAction(
            identifier: WeeklyCheckInReminderService.snoozeActionIdentifier,
            title: "Remind Later",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: WeeklyCheckInReminderService.categoryIdentifier,
            actions: [snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.notification.request.content.userInfo["route"] as? String == "weeklyCheckIn" else {
            return
        }

        if response.actionIdentifier == WeeklyCheckInReminderService.snoozeActionIdentifier {
            NotificationCenter.default.post(name: .weeklyCheckInNotificationSnoozed, object: nil)
        } else {
            NotificationCenter.default.post(name: .weeklyCheckInNotificationTapped, object: nil)
        }
    }
}

@main
struct RoadToTheosis: App {
    @UIApplicationDelegateAdaptor(AppNotificationDelegate.self) private var appNotificationDelegate
    private let modelContainer = AppPersistence.makeModelContainer()

    var body: some Scene {
        WindowGroup {
            AppShellView()
        }
        .modelContainer(modelContainer)
    }
}
