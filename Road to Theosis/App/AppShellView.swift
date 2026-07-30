import SwiftUI

struct AppShellView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @State private var backgroundTheme: AppBackgroundTheme = .blood
    @State private var dashboard = DashboardViewModel()
    @State private var logEntries: [LogEntry] = []
    @State private var isShowingWelcome = false

    var body: some View {
        TabView {
            NavigationStack {
                HeadwayView(
                    backgroundTheme: $backgroundTheme,
                    dashboard: $dashboard,
                    logEntries: $logEntries
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
                SettingsView(backgroundTheme: $backgroundTheme, onShowWelcome: {
                    isShowingWelcome = true
                }) { entry in
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
            guard !hasSeenWelcome else { return }
            isShowingWelcome = true
        }
    }
}

#Preview {
    AppShellView()
}
