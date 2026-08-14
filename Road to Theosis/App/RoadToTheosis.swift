import SwiftData
import SwiftUI
import UIKit
import UserNotifications

final class AppNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
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

        NotificationCenter.default.post(name: .weeklyCheckInNotificationTapped, object: nil)
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
