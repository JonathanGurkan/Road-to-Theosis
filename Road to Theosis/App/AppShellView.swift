import SwiftData
import SwiftUI

struct AppShellView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredLogEntry.occurredAt, order: .reverse) private var storedLogEntries: [StoredLogEntry]
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
                    purityCalculationDate: $purityCalculationDate,
                    onSaveEntry: saveEntry
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
            syncLogEntriesFromStore()
            recalculatePurity()
            guard !hasSeenWelcome else { return }
            isShowingWelcome = true
        }
        .onChange(of: storedLogEntries.map(\.updatedAt)) { _, _ in
            syncLogEntriesFromStore()
            recalculatePurity()
        }
        .onChange(of: purityStrictnessRaw) { _, _ in
            recalculatePurity()
        }
    }

    private func saveEntry(_ entry: LogEntry) {
        persistEntry(entry)
        purityCalculationDate = max(purityCalculationDate, entry.occurredAt)
        logEntries.insert(entry, at: 0)

        recalculatePurity()
    }

    private func syncLogEntriesFromStore() {
        logEntries = storedLogEntries.map(\.entry)
        purityCalculationDate = logEntries.map(\.occurredAt).max() ?? Date()
    }

    private func persistEntry(_ entry: LogEntry) {
        guard !storedLogEntries.contains(where: { $0.id == entry.id }) else { return }

        modelContext.insert(StoredLogEntry(entry: entry))
        try? modelContext.save()
    }

    private func recalculatePurity() {
        dashboard.rebuild(from: logEntries, now: purityCalculationDate, strictness: purityStrictness)
    }
}

#Preview {
    AppShellView()
}
