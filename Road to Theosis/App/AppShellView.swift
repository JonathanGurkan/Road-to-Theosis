import SwiftData
import SwiftUI

struct AppShellView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredLogEntry.occurredAt, order: .reverse) private var storedLogEntries: [StoredLogEntry]
    @Query(sort: \StoredAppPreference.updatedAt, order: .reverse) private var storedPreferences: [StoredAppPreference]
    @State private var preferences = AppPreferenceStore()
    @State private var dashboard = DashboardViewModel()
    @State private var logEntries: [LogEntry] = []
    @State private var purityCalculationDate = Date()
    @State private var isShowingWelcome = false

    private var backgroundThemeBinding: Binding<AppBackgroundTheme> {
        Binding {
            preferences.backgroundTheme
        } set: { newValue in
            preferences.backgroundTheme = newValue
        }
    }

    var body: some View {
        TabView {
            NavigationStack {
                HeadwayView(
                    backgroundTheme: backgroundThemeBinding,
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
                TimelineView(
                    backgroundTheme: backgroundThemeBinding,
                    logEntries: $logEntries,
                    onUpdateEntry: updateEntry,
                    onDeleteEntry: deleteEntry
                )
            }
            .tabItem {
                Label("Timeline", systemImage: "clock.arrow.circlepath")
            }

            NavigationStack {
                SettingsView(
                    backgroundTheme: backgroundThemeBinding,
                    dashboard: $dashboard,
                    logEntries: $logEntries,
                    purityCalculationDate: $purityCalculationDate,
                    onShowWelcome: {
                        isShowingWelcome = true
                    },
                    onDeleteAllData: deleteAllData
                ) { entry in
                    saveEntry(entry)
                }
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .environment(preferences)
        .tint(preferences.backgroundTheme.glowColor)
        .toolbarBackground(.thinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .fullScreenCover(isPresented: $isShowingWelcome) {
            WelcomeView(isPresented: $isShowingWelcome) {
                preferences.hasSeenWelcome = true
            }
        }
        .task {
            syncLogEntriesFromStore()
            preferences.load(from: storedPreferences)
            if preferences.mirrorCurrentPreferences(into: modelContext, storedPreferences: storedPreferences) {
                preferences.removeLegacyUserDefaults()
            }
            recalculatePurity()
            guard !preferences.hasSeenWelcome else { return }
            isShowingWelcome = true
        }
        .onChange(of: storedLogEntries.map(\.updatedAt)) { _, _ in
            syncLogEntriesFromStore()
            recalculatePurity()
        }
        .onChange(of: storedPreferences.map(\.updatedAt)) { _, _ in
            preferences.load(from: storedPreferences)
        }
        .onChange(of: preferences.signature) { _, _ in
            preferences.mirrorCurrentPreferences(into: modelContext, storedPreferences: storedPreferences)
        }
        .onChange(of: preferences.purityStrictnessRaw) { _, _ in
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

    private func updateEntry(_ entry: LogEntry) {
        guard let storedEntry = storedLogEntries.first(where: { $0.id == entry.id }) else { return }

        storedEntry.kindRawValue = entry.kind.rawValue
        storedEntry.sectionTitle = entry.sectionTitle
        storedEntry.sinTitle = entry.sinTitle
        storedEntry.note = entry.note
        storedEntry.prayerMinutes = entry.prayerMinutes
        storedEntry.prayerDurationSeconds = entry.prayerDurationSeconds
        storedEntry.progressPercentage = entry.progressPercentage
        storedEntry.checkInRecordJSON = entry.checkInRecordJSON
        storedEntry.occurredAt = entry.occurredAt
        storedEntry.updatedAt = Date()
        try? modelContext.save()

        syncLogEntriesFromStore()
        recalculatePurity()
    }

    private func deleteEntry(_ entry: LogEntry) {
        guard let storedEntry = storedLogEntries.first(where: { $0.id == entry.id }) else { return }

        modelContext.delete(storedEntry)
        try? modelContext.save()

        syncLogEntriesFromStore()
        recalculatePurity()
    }

    private func persistEntry(_ entry: LogEntry) {
        guard !storedLogEntries.contains(where: { $0.id == entry.id }) else { return }

        modelContext.insert(StoredLogEntry(entry: entry))
        try? modelContext.save()
    }

    private func deleteAllData() {
        for storedLogEntry in storedLogEntries {
            modelContext.delete(storedLogEntry)
        }

        for storedPreference in storedPreferences {
            modelContext.delete(storedPreference)
        }

        try? modelContext.save()
        preferences.reset()
        preferences.removeLegacyUserDefaults()
        preferences.mirrorCurrentPreferences(into: modelContext, storedPreferences: [])

        logEntries = []
        purityCalculationDate = Date()
        dashboard.rebuild(from: [], now: purityCalculationDate, strictness: preferences.purityStrictness)
        isShowingWelcome = true
    }

    private func recalculatePurity() {
        dashboard.rebuild(from: logEntries, now: purityCalculationDate, strictness: preferences.purityStrictness)
    }
}

#Preview {
    AppShellView()
}
