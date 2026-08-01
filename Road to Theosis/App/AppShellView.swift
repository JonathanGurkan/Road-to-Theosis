import SwiftUI

struct AppShellView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @State private var backgroundTheme: AppBackgroundTheme = .blood
    @State private var dashboard = DashboardViewModel()
    @State private var logEntries: [LogEntry] = []
    @State private var purityCalculationDate = Date()
    @State private var isShowingWelcome = false
    @AppStorage(PurityStrictness.storageKey) private var purityStrictnessRaw = PurityStrictness.normal.rawValue

    private var purityStrictness: PurityStrictness {
        PurityStrictness(rawValue: purityStrictnessRaw) ?? .normal
    }

    var body: some View {
        TabView {
            NavigationStack {
                HeadwayView(
                    backgroundTheme: $backgroundTheme,
                    dashboard: $dashboard,
                    logEntries: $logEntries,
                    purityCalculationDate: $purityCalculationDate
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
                    dashboard: $dashboard,
                    logEntries: $logEntries,
                    purityCalculationDate: $purityCalculationDate,
                    onShowWelcome: {
                        isShowingWelcome = true
                    }
                ) { entry in
                    saveEntry(entry)
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
            recalculatePurity()
            guard !hasSeenWelcome else { return }
            isShowingWelcome = true
        }
        .onChange(of: purityStrictnessRaw) { _, _ in
            recalculatePurity()
        }
    }

    private func saveEntry(_ entry: LogEntry) {
        purityCalculationDate = max(purityCalculationDate, entry.occurredAt)
        logEntries.insert(entry, at: 0)
        dashboard.record(entry)

        recalculatePurity()
    }

    private func recalculatePurity() {
        dashboard.recalculatePurity(from: logEntries, now: purityCalculationDate, strictness: purityStrictness)
    }
}

#Preview {
    AppShellView()
}
