import SwiftData
import SwiftUI

private enum AppFullScreenPresentation: Hashable, Identifiable {
    case welcome
    case helpGuide
    case initialCheckIn
    case initialCalibrationSuccess
    case weeklyCheckIn

    var id: Self { self }
}

struct AppShellView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \StoredLogEntry.occurredAt, order: .reverse) private var storedLogEntries: [StoredLogEntry]
    @Query(sort: \StoredAppPreference.updatedAt, order: .reverse) private var storedPreferences: [StoredAppPreference]
    @State private var preferences = AppPreferenceStore()
    @State private var dashboard = DashboardViewModel()
    @State private var logEntries: [LogEntry] = []
    @State private var purityCalculationDate = Date()
    @State private var activeFullScreenPresentation: AppFullScreenPresentation?
    @State private var shouldStartInitialCheckInAfterWelcome = false
    private let weeklyCheckInReminderService = WeeklyCheckInReminderService()

    private var backgroundThemeBinding: Binding<AppBackgroundTheme> {
        Binding {
            preferences.backgroundTheme
        } set: { newValue in
            preferences.backgroundTheme = newValue
        }
    }

    private var welcomePresentationBinding: Binding<Bool> {
        Binding {
            activeFullScreenPresentation == .welcome
        } set: { isPresented in
            if !isPresented {
                activeFullScreenPresentation = nil
            }
        }
    }

    private var helpGuidePresentationBinding: Binding<Bool> {
        Binding {
            activeFullScreenPresentation == .helpGuide
        } set: { isPresented in
            if !isPresented {
                activeFullScreenPresentation = nil
            }
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
                    onSaveEntry: saveEntry,
                    onUpdateEntry: updateEntry,
                    onDeleteEntry: deleteEntry
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
                    onShowHelpGuide: {
                        activeFullScreenPresentation = .helpGuide
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
        .fullScreenCover(item: $activeFullScreenPresentation) { presentation in
            fullScreenPresentationView(for: presentation)
                .environment(preferences)
        }
        .task {
            syncLogEntriesFromStore()
            preferences.load(from: storedPreferences)
            if preferences.mirrorCurrentPreferences(into: modelContext, storedPreferences: storedPreferences) {
                preferences.removeLegacyUserDefaults()
            }
            recalculatePurity()
            await notifyForWeeklyCheckInIfDue()
            guard !preferences.hasSeenWelcome else { return }
            activeFullScreenPresentation = .welcome
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await notifyForWeeklyCheckInIfDue()
            }
        }
        .onChange(of: activeFullScreenPresentation) { _, presentation in
            guard presentation == nil else { return }
            startInitialCheckInIfReady()
        }
        .onReceive(NotificationCenter.default.publisher(for: .weeklyCheckInNotificationTapped)) { _ in
            preferences.weeklyCheckInSnoozedUntil = 0
            activeFullScreenPresentation = .weeklyCheckIn
        }
        .onReceive(NotificationCenter.default.publisher(for: .weeklyCheckInNotificationSnoozed)) { _ in
            Task {
                await weeklyCheckInReminderService.snooze(preferences: preferences)
            }
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

    @ViewBuilder
    private func fullScreenPresentationView(for presentation: AppFullScreenPresentation) -> some View {
        switch presentation {
        case .welcome:
            WelcomeView(isPresented: welcomePresentationBinding) {
                shouldStartInitialCheckInAfterWelcome = true
                activeFullScreenPresentation = nil
            }
        case .helpGuide:
            HelpGuideView(isPresented: helpGuidePresentationBinding) {
                activeFullScreenPresentation = nil
            }
        case .initialCheckIn:
            CheckInView(
                backgroundTheme: backgroundThemeBinding,
                dashboard: dashboard,
                allowsCancel: false,
                headerEyebrow: "Initial calibration",
                headerTitle: "Answer once so the app starts from your real baseline.",
                headerSubtitle: "This first check-in is required. It creates your starting timeline entry and calibrates the dashboard before you begin.",
                onSave: saveEntry
            ) {
                preferences.hasSeenWelcome = true
                activeFullScreenPresentation = nil
                Task { @MainActor in
                    activeFullScreenPresentation = .initialCalibrationSuccess
                }
            }
        case .initialCalibrationSuccess:
            OnboardingSuccessView {
                activeFullScreenPresentation = nil
            }
        case .weeklyCheckIn:
            CheckInView(
                backgroundTheme: backgroundThemeBinding,
                dashboard: dashboard,
                onSave: saveEntry
            )
        }
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
        storedEntry.connectedSins = entry.connectedSins
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
        shouldStartInitialCheckInAfterWelcome = false
        activeFullScreenPresentation = .welcome
    }

    private func recalculatePurity() {
        dashboard.rebuild(from: logEntries, now: purityCalculationDate, strictness: preferences.purityStrictness)
    }

    private func startInitialCheckInIfReady() {
        guard shouldStartInitialCheckInAfterWelcome, activeFullScreenPresentation == nil else { return }

        shouldStartInitialCheckInAfterWelcome = false
        activeFullScreenPresentation = .initialCheckIn
    }

    private func notifyForWeeklyCheckInIfDue() async {
        await weeklyCheckInReminderService.notifyIfDue(preferences: preferences)
    }
}

#Preview {
    AppShellView()
}
