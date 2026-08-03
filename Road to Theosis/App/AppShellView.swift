import SwiftData
import SwiftUI

struct AppShellView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredLogEntry.occurredAt, order: .reverse) private var storedLogEntries: [StoredLogEntry]
    @Query(sort: \StoredAppPreference.updatedAt, order: .reverse) private var storedPreferences: [StoredAppPreference]
    @AppStorage(AppPreferenceKey.hasSeenWelcome.storageKey) private var hasSeenWelcome = false
    @AppStorage(AppPreferenceKey.backgroundTheme.storageKey) private var backgroundThemeRaw = AppBackgroundTheme.blood.rawValue
    @AppStorage(AppPreferenceKey.compactSinRows.storageKey) private var compactSinRows = false
    @AppStorage(AppPreferenceKey.customDefenseVersesBySin.storageKey) private var customDefenseVersesBySin = "{}"
    @AppStorage(AppPreferenceKey.enableVerseInventory.storageKey) private var enableVerseInventory = true
    @AppStorage(AppPreferenceKey.focusSliderStyle.storageKey) private var focusSliderStyleRaw = FocusSliderStyle.clean.rawValue
    @AppStorage(AppPreferenceKey.focusedSinReferences.storageKey) private var focusedSinReferences = "[]"
    @AppStorage(AppPreferenceKey.greetingWeatherBreezyThresholdKilometersPerHour.storageKey) private var greetingWeatherBreezyThresholdKilometersPerHour = GreetingWeatherThresholds.defaultBreezyThresholdKilometersPerHour
    @AppStorage(AppPreferenceKey.greetingWeatherColdThresholdCelsius.storageKey) private var greetingWeatherColdThresholdCelsius = GreetingWeatherThresholds.defaultColdThresholdCelsius
    @AppStorage(AppPreferenceKey.greetingWeatherWarmThresholdCelsius.storageKey) private var greetingWeatherWarmThresholdCelsius = GreetingWeatherThresholds.defaultWarmThresholdCelsius
    @AppStorage(AppPreferenceKey.homeScreenLayout.storageKey) private var homeScreenLayoutData = HomeScreenLayout.defaultStorageValue
    @AppStorage(AppPreferenceKey.isGreetingWeatherEnabled.storageKey) private var isGreetingWeatherEnabled = true
    @AppStorage(AppPreferenceKey.isPrayerTimingEnabled.storageKey) private var isPrayerTimingEnabled = true
    @AppStorage(AppPreferenceKey.keepScreenAwakeDuringPrayer.storageKey) private var keepScreenAwakeDuringPrayer = true
    @AppStorage(AppPreferenceKey.prayerTimerCountingMode.storageKey) private var prayerTimerCountingModeRaw = PrayerTimerCountingMode.foreground.rawValue
    @AppStorage(AppPreferenceKey.purityStrictness.storageKey) private var purityStrictnessRaw = PurityStrictness.normal.rawValue
    @AppStorage(AppPreferenceKey.showRecentActivity.storageKey) private var showRecentActivity = true
    @AppStorage(AppPreferenceKey.showVerseApplications.storageKey) private var showVerseApplications = true
    @AppStorage(AppPreferenceKey.timelineRange.storageKey) private var timelineRangeRaw = TimelineRange.always.rawValue
    @AppStorage(AppPreferenceKey.usesFocusProgressSliders.storageKey) private var usesFocusProgressSliders = true
    @State private var dashboard = DashboardViewModel()
    @State private var logEntries: [LogEntry] = []
    @State private var purityCalculationDate = Date()
    @State private var isShowingWelcome = false

    private var backgroundTheme: AppBackgroundTheme {
        AppBackgroundTheme(rawValue: backgroundThemeRaw) ?? .blood
    }

    private var backgroundThemeBinding: Binding<AppBackgroundTheme> {
        Binding {
            backgroundTheme
        } set: { newValue in
            backgroundThemeRaw = newValue.rawValue
        }
    }

    private var purityStrictness: PurityStrictness {
        PurityStrictness(rawValue: purityStrictnessRaw) ?? .normal
    }

    private var currentPreferenceValues: [String: String] {
        [
            AppPreferenceKey.backgroundTheme.storageKey: backgroundThemeRaw,
            AppPreferenceKey.compactSinRows.storageKey: String(compactSinRows),
            AppPreferenceKey.customDefenseVersesBySin.storageKey: customDefenseVersesBySin,
            AppPreferenceKey.enableVerseInventory.storageKey: String(enableVerseInventory),
            AppPreferenceKey.focusSliderStyle.storageKey: focusSliderStyleRaw,
            AppPreferenceKey.focusedSinReferences.storageKey: focusedSinReferences,
            AppPreferenceKey.greetingWeatherBreezyThresholdKilometersPerHour.storageKey: String(greetingWeatherBreezyThresholdKilometersPerHour),
            AppPreferenceKey.greetingWeatherColdThresholdCelsius.storageKey: String(greetingWeatherColdThresholdCelsius),
            AppPreferenceKey.greetingWeatherWarmThresholdCelsius.storageKey: String(greetingWeatherWarmThresholdCelsius),
            AppPreferenceKey.hasSeenWelcome.storageKey: String(hasSeenWelcome),
            AppPreferenceKey.homeScreenLayout.storageKey: homeScreenLayoutData,
            AppPreferenceKey.isGreetingWeatherEnabled.storageKey: String(isGreetingWeatherEnabled),
            AppPreferenceKey.isPrayerTimingEnabled.storageKey: String(isPrayerTimingEnabled),
            AppPreferenceKey.keepScreenAwakeDuringPrayer.storageKey: String(keepScreenAwakeDuringPrayer),
            AppPreferenceKey.prayerTimerCountingMode.storageKey: prayerTimerCountingModeRaw,
            AppPreferenceKey.purityStrictness.storageKey: purityStrictnessRaw,
            AppPreferenceKey.showRecentActivity.storageKey: String(showRecentActivity),
            AppPreferenceKey.showVerseApplications.storageKey: String(showVerseApplications),
            AppPreferenceKey.timelineRange.storageKey: timelineRangeRaw,
            AppPreferenceKey.usesFocusProgressSliders.storageKey: String(usesFocusProgressSliders)
        ]
    }

    private var preferenceSignature: String {
        currentPreferenceValues
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "\n")
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
                TimelineView(backgroundTheme: backgroundThemeBinding, logEntries: $logEntries)
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
            applyStoredPreferences()
            mirrorCurrentPreferences()
            recalculatePurity()
            guard !hasSeenWelcome else { return }
            isShowingWelcome = true
        }
        .onChange(of: storedLogEntries.map(\.updatedAt)) { _, _ in
            syncLogEntriesFromStore()
            recalculatePurity()
        }
        .onChange(of: storedPreferences.map(\.updatedAt)) { _, _ in
            applyStoredPreferences()
        }
        .onChange(of: preferenceSignature) { _, _ in
            mirrorCurrentPreferences()
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

    private func deleteAllData() {
        for storedLogEntry in storedLogEntries {
            modelContext.delete(storedLogEntry)
        }

        for storedPreference in storedPreferences {
            modelContext.delete(storedPreference)
        }

        try? modelContext.save()

        UserDefaults.standard.removeObject(forKey: AppPersistence.iCloudSyncEnabledKey)
        for key in AppPreferenceKey.allCases.map(\.storageKey) {
            UserDefaults.standard.removeObject(forKey: key)
        }

        backgroundThemeRaw = AppBackgroundTheme.blood.rawValue
        compactSinRows = false
        customDefenseVersesBySin = "{}"
        enableVerseInventory = true
        focusSliderStyleRaw = FocusSliderStyle.clean.rawValue
        focusedSinReferences = "[]"
        greetingWeatherBreezyThresholdKilometersPerHour = GreetingWeatherThresholds.defaultBreezyThresholdKilometersPerHour
        greetingWeatherColdThresholdCelsius = GreetingWeatherThresholds.defaultColdThresholdCelsius
        greetingWeatherWarmThresholdCelsius = GreetingWeatherThresholds.defaultWarmThresholdCelsius
        hasSeenWelcome = false
        homeScreenLayoutData = HomeScreenLayout.defaultStorageValue
        isGreetingWeatherEnabled = true
        isPrayerTimingEnabled = true
        keepScreenAwakeDuringPrayer = true
        prayerTimerCountingModeRaw = PrayerTimerCountingMode.foreground.rawValue
        purityStrictnessRaw = PurityStrictness.normal.rawValue
        showRecentActivity = true
        showVerseApplications = true
        timelineRangeRaw = TimelineRange.always.rawValue
        usesFocusProgressSliders = true

        logEntries = []
        purityCalculationDate = Date()
        dashboard.rebuild(from: [], now: purityCalculationDate, strictness: purityStrictness)
        isShowingWelcome = true
    }

    private func mirrorCurrentPreferences() {
        for (key, value) in currentPreferenceValues {
            if let storedPreference = storedPreferences.first(where: { $0.key == key }) {
                guard storedPreference.value != value else { continue }
                storedPreference.value = value
                storedPreference.updatedAt = Date()
            } else {
                modelContext.insert(StoredAppPreference(key: key, value: value))
            }
        }

        try? modelContext.save()
    }

    private func applyStoredPreferences() {
        for key in AppPreferenceKey.allCases.map(\.storageKey) {
            guard let value = storedPreferences.first(where: { $0.key == key })?.value else { continue }
            applyPreferenceValue(value, forKey: key)
        }
    }

    private func applyPreferenceValue(_ value: String, forKey key: String) {
        switch key {
        case AppPreferenceKey.backgroundTheme.storageKey:
            backgroundThemeRaw = value
        case AppPreferenceKey.compactSinRows.storageKey:
            compactSinRows = value == "true"
        case AppPreferenceKey.customDefenseVersesBySin.storageKey:
            customDefenseVersesBySin = value
        case AppPreferenceKey.enableVerseInventory.storageKey:
            enableVerseInventory = value == "true"
        case AppPreferenceKey.focusSliderStyle.storageKey:
            focusSliderStyleRaw = value
        case AppPreferenceKey.focusedSinReferences.storageKey:
            focusedSinReferences = value
        case AppPreferenceKey.greetingWeatherBreezyThresholdKilometersPerHour.storageKey:
            greetingWeatherBreezyThresholdKilometersPerHour = Double(value) ?? GreetingWeatherThresholds.defaultBreezyThresholdKilometersPerHour
        case AppPreferenceKey.greetingWeatherColdThresholdCelsius.storageKey:
            greetingWeatherColdThresholdCelsius = Double(value) ?? GreetingWeatherThresholds.defaultColdThresholdCelsius
        case AppPreferenceKey.greetingWeatherWarmThresholdCelsius.storageKey:
            greetingWeatherWarmThresholdCelsius = Double(value) ?? GreetingWeatherThresholds.defaultWarmThresholdCelsius
        case AppPreferenceKey.hasSeenWelcome.storageKey:
            hasSeenWelcome = value == "true"
        case AppPreferenceKey.homeScreenLayout.storageKey:
            homeScreenLayoutData = value
        case AppPreferenceKey.isGreetingWeatherEnabled.storageKey:
            isGreetingWeatherEnabled = value == "true"
        case AppPreferenceKey.isPrayerTimingEnabled.storageKey:
            isPrayerTimingEnabled = value == "true"
        case AppPreferenceKey.keepScreenAwakeDuringPrayer.storageKey:
            keepScreenAwakeDuringPrayer = value == "true"
        case AppPreferenceKey.prayerTimerCountingMode.storageKey:
            prayerTimerCountingModeRaw = value
        case AppPreferenceKey.purityStrictness.storageKey:
            purityStrictnessRaw = value
        case AppPreferenceKey.showRecentActivity.storageKey:
            showRecentActivity = value == "true"
        case AppPreferenceKey.showVerseApplications.storageKey:
            showVerseApplications = value == "true"
        case AppPreferenceKey.timelineRange.storageKey:
            timelineRangeRaw = value
        case AppPreferenceKey.usesFocusProgressSliders.storageKey:
            usesFocusProgressSliders = value == "true"
        default:
            break
        }
    }

    private func recalculatePurity() {
        dashboard.rebuild(from: logEntries, now: purityCalculationDate, strictness: purityStrictness)
    }
}

#Preview {
    AppShellView()
}
