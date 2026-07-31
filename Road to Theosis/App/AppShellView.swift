import SwiftUI

struct AppShellView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @AppStorage("lastDailyProgressDate") private var lastDailyProgressDate = ""
    @State private var backgroundTheme: AppBackgroundTheme = .blood
    @State private var dashboard = DashboardViewModel()
    @State private var logEntries: [LogEntry] = []
    @State private var isShowingWelcome = false
    @State private var showVictorySwipeAction = false

    var body: some View {
        TabView {
            NavigationStack {
                HeadwayView(
                    backgroundTheme: $backgroundTheme,
                    dashboard: $dashboard,
                    logEntries: $logEntries,
                    showVictorySwipeAction: showVictorySwipeAction
                )
            }
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }

            NavigationStack {
                TimelineView(backgroundTheme: $backgroundTheme, logEntries: $logEntries)
            }
            .tabItem {
                Label("Timeline", systemImage: "clock.arrow.circlepath")
            }

            NavigationStack {
                SettingsView(
                    backgroundTheme: $backgroundTheme,
                    showVictorySwipeAction: $showVictorySwipeAction,
                    onShowWelcome: {
                        isShowingWelcome = true
                    }
                ) { entry in
                    logEntries.insert(entry, at: 0)
                    dashboard.record(entry)
                }
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(backgroundTheme.glowColor)
        .toolbarBackground(.thinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .fullScreenCover(isPresented: $isShowingWelcome) {
            WelcomeView(isPresented: $isShowingWelcome) {
                hasSeenWelcome = true
            }
        }
        .task {
            applyDailyProgressIfNeeded()
            guard !hasSeenWelcome else { return }
            isShowingWelcome = true
        }
    }

    private func applyDailyProgressIfNeeded(on date: Date = .now) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        let todayStamp = Self.dailyProgressFormatter.string(from: today)

        guard !lastDailyProgressDate.isEmpty,
              let lastDate = Self.dailyProgressFormatter.date(from: lastDailyProgressDate) else {
            lastDailyProgressDate = todayStamp
            return
        }

        let elapsedDays = calendar.dateComponents([.day], from: lastDate, to: today).day ?? 0
        guard elapsedDays > 0 else { return }

        dashboard.advanceDailyProgress(days: elapsedDays)
        lastDailyProgressDate = todayStamp
    }

    private static let dailyProgressFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

#Preview {
    AppShellView()
}
