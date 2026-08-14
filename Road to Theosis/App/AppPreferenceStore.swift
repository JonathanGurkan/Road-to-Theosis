import Foundation
import Observation
import SwiftData

@Observable
final class AppPreferenceStore {
    var hasSeenWelcome = false
    var backgroundThemeRaw = AppBackgroundTheme.blood.rawValue
    var checkInEnabledQuestionIDsRaw = CheckInQuestionnaire.defaultQuestionIDs.joined(separator: ",")
    var compactSinRows = false
    var customDefenseVersesBySin = "{}"
    var enableVerseInventory = true
    var focusSliderStyleRaw = FocusSliderStyle.clean.rawValue
    var focusedSinReferences = "[]"
    var greetingWeatherBreezyThresholdKilometersPerHour = GreetingWeatherThresholds.defaultBreezyThresholdKilometersPerHour
    var greetingWeatherColdThresholdCelsius = GreetingWeatherThresholds.defaultColdThresholdCelsius
    var greetingWeatherWarmThresholdCelsius = GreetingWeatherThresholds.defaultWarmThresholdCelsius
    var homeScreenLayoutData = HomeScreenLayout.defaultStorageValue
    var isGreetingWeatherEnabled = true
    var isICloudSyncEnabled = false
    var isPrayerTimingEnabled = true
    var isWeeklyCheckInReminderEnabled = false
    var keepScreenAwakeDuringPrayer = true
    var lastWeeklyCheckInReminderDay = ""
    var prayerTimerCountingModeRaw = PrayerTimerCountingMode.foreground.rawValue
    var purityStrictnessRaw = PurityStrictness.normal.rawValue
    var showRecentActivity = true
    var showVerseApplications = true
    var timelineRangeRaw = TimelineRange.always.rawValue
    var usesFocusProgressSliders = true
    var weeklyCheckInHour = 9
    var weeklyCheckInMinute = 0
    var weeklyCheckInWeekdayRaw = CheckInWeekday.sunday.rawValue

    var backgroundTheme: AppBackgroundTheme {
        get { AppBackgroundTheme(rawValue: backgroundThemeRaw) ?? .blood }
        set { backgroundThemeRaw = newValue.rawValue }
    }

    var checkInEnabledQuestionIDs: Set<String> {
        get {
            let ids = checkInEnabledQuestionIDsRaw
                .split(separator: ",")
                .map(String.init)
            return Set(ids.isEmpty ? CheckInQuestionnaire.defaultQuestionIDs : ids)
        }
        set {
            let orderedIDs = CheckInQuestionnaire.defaultQuestionIDs.filter { newValue.contains($0) }
            checkInEnabledQuestionIDsRaw = orderedIDs.joined(separator: ",")
        }
    }

    var weeklyCheckInWeekday: CheckInWeekday {
        get { CheckInWeekday(rawValue: weeklyCheckInWeekdayRaw) ?? .sunday }
        set { weeklyCheckInWeekdayRaw = newValue.rawValue }
    }

    var focusSliderStyle: FocusSliderStyle {
        get { FocusSliderStyle(rawValue: focusSliderStyleRaw) ?? .clean }
        set { focusSliderStyleRaw = newValue.rawValue }
    }

    var prayerTimerCountingMode: PrayerTimerCountingMode {
        get { PrayerTimerCountingMode(rawValue: prayerTimerCountingModeRaw) ?? .foreground }
        set { prayerTimerCountingModeRaw = newValue.rawValue }
    }

    var purityStrictness: PurityStrictness {
        get { PurityStrictness(rawValue: purityStrictnessRaw) ?? .normal }
        set { purityStrictnessRaw = newValue.rawValue }
    }

    var timelineRange: TimelineRange {
        get { TimelineRange(rawValue: timelineRangeRaw) ?? .always }
        set { timelineRangeRaw = newValue.rawValue }
    }

    var homeScreenLayout: HomeScreenLayout {
        get { HomeScreenLayout.decoded(from: homeScreenLayoutData) }
        set { homeScreenLayoutData = newValue.encoded() }
    }

    var greetingWeatherThresholds: GreetingWeatherThresholds {
        GreetingWeatherThresholds(
            warmThresholdCelsius: greetingWeatherWarmThresholdCelsius,
            coldThresholdCelsius: greetingWeatherColdThresholdCelsius,
            breezyThresholdKilometersPerHour: greetingWeatherBreezyThresholdKilometersPerHour
        )
    }

    var currentValues: [String: String] {
        [
            AppPreferenceKey.backgroundTheme.storageKey: backgroundThemeRaw,
            AppPreferenceKey.checkInEnabledQuestionIDs.storageKey: checkInEnabledQuestionIDsRaw,
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
            AppPreferenceKey.isICloudSyncEnabled.storageKey: String(isICloudSyncEnabled),
            AppPreferenceKey.isPrayerTimingEnabled.storageKey: String(isPrayerTimingEnabled),
            AppPreferenceKey.isWeeklyCheckInReminderEnabled.storageKey: String(isWeeklyCheckInReminderEnabled),
            AppPreferenceKey.keepScreenAwakeDuringPrayer.storageKey: String(keepScreenAwakeDuringPrayer),
            AppPreferenceKey.lastWeeklyCheckInReminderDay.storageKey: lastWeeklyCheckInReminderDay,
            AppPreferenceKey.prayerTimerCountingMode.storageKey: prayerTimerCountingModeRaw,
            AppPreferenceKey.purityStrictness.storageKey: purityStrictnessRaw,
            AppPreferenceKey.showRecentActivity.storageKey: String(showRecentActivity),
            AppPreferenceKey.showVerseApplications.storageKey: String(showVerseApplications),
            AppPreferenceKey.timelineRange.storageKey: timelineRangeRaw,
            AppPreferenceKey.usesFocusProgressSliders.storageKey: String(usesFocusProgressSliders),
            AppPreferenceKey.weeklyCheckInHour.storageKey: String(weeklyCheckInHour),
            AppPreferenceKey.weeklyCheckInMinute.storageKey: String(weeklyCheckInMinute),
            AppPreferenceKey.weeklyCheckInWeekday.storageKey: String(weeklyCheckInWeekdayRaw)
        ]
    }

    var signature: String {
        currentValues
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "\n")
    }

    func load(from storedPreferences: [StoredAppPreference]) {
        let storedValues = Dictionary(uniqueKeysWithValues: storedPreferences.map { ($0.key, $0.value) })

        for key in AppPreferenceKey.allCases {
            if let value = storedValues[key.storageKey] {
                applyPreferenceValue(value, forKey: key.storageKey)
            } else if let legacyValue = key.legacyStoredValue() {
                applyPreferenceValue(legacyValue, forKey: key.storageKey)
            }
        }
    }

    @discardableResult
    func mirrorCurrentPreferences(into modelContext: ModelContext, storedPreferences: [StoredAppPreference]) -> Bool {
        for (key, value) in currentValues {
            if let storedPreference = storedPreferences.first(where: { $0.key == key }) {
                guard storedPreference.value != value else { continue }
                storedPreference.value = value
                storedPreference.updatedAt = Date()
            } else {
                modelContext.insert(StoredAppPreference(key: key, value: value))
            }
        }

        do {
            try modelContext.save()
            return true
        } catch {
            return false
        }
    }

    func reset() {
        hasSeenWelcome = false
        backgroundThemeRaw = AppBackgroundTheme.blood.rawValue
        checkInEnabledQuestionIDsRaw = CheckInQuestionnaire.defaultQuestionIDs.joined(separator: ",")
        compactSinRows = false
        customDefenseVersesBySin = "{}"
        enableVerseInventory = true
        focusSliderStyleRaw = FocusSliderStyle.clean.rawValue
        focusedSinReferences = "[]"
        greetingWeatherBreezyThresholdKilometersPerHour = GreetingWeatherThresholds.defaultBreezyThresholdKilometersPerHour
        greetingWeatherColdThresholdCelsius = GreetingWeatherThresholds.defaultColdThresholdCelsius
        greetingWeatherWarmThresholdCelsius = GreetingWeatherThresholds.defaultWarmThresholdCelsius
        homeScreenLayoutData = HomeScreenLayout.defaultStorageValue
        isGreetingWeatherEnabled = true
        isICloudSyncEnabled = false
        isPrayerTimingEnabled = true
        isWeeklyCheckInReminderEnabled = false
        keepScreenAwakeDuringPrayer = true
        lastWeeklyCheckInReminderDay = ""
        prayerTimerCountingModeRaw = PrayerTimerCountingMode.foreground.rawValue
        purityStrictnessRaw = PurityStrictness.normal.rawValue
        showRecentActivity = true
        showVerseApplications = true
        timelineRangeRaw = TimelineRange.always.rawValue
        usesFocusProgressSliders = true
        weeklyCheckInHour = 9
        weeklyCheckInMinute = 0
        weeklyCheckInWeekdayRaw = CheckInWeekday.sunday.rawValue
    }

    func removeLegacyUserDefaults() {
        for key in AppPreferenceKey.allCases.map(\.storageKey) {
            UserDefaults.standard.removeObject(forKey: key)
        }

        UserDefaults.standard.removeObject(forKey: AppPersistence.legacyICloudSyncEnabledKey)
    }

    private func applyPreferenceValue(_ value: String, forKey key: String) {
        switch key {
        case AppPreferenceKey.backgroundTheme.storageKey:
            backgroundThemeRaw = value
        case AppPreferenceKey.checkInEnabledQuestionIDs.storageKey:
            checkInEnabledQuestionIDsRaw = value
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
        case AppPreferenceKey.isICloudSyncEnabled.storageKey:
            isICloudSyncEnabled = value == "true"
        case AppPreferenceKey.isPrayerTimingEnabled.storageKey:
            isPrayerTimingEnabled = value == "true"
        case AppPreferenceKey.isWeeklyCheckInReminderEnabled.storageKey:
            isWeeklyCheckInReminderEnabled = value == "true"
        case AppPreferenceKey.keepScreenAwakeDuringPrayer.storageKey:
            keepScreenAwakeDuringPrayer = value == "true"
        case AppPreferenceKey.lastWeeklyCheckInReminderDay.storageKey:
            lastWeeklyCheckInReminderDay = value
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
        case AppPreferenceKey.weeklyCheckInHour.storageKey:
            weeklyCheckInHour = min(23, max(0, Int(value) ?? 9))
        case AppPreferenceKey.weeklyCheckInMinute.storageKey:
            weeklyCheckInMinute = min(59, max(0, Int(value) ?? 0))
        case AppPreferenceKey.weeklyCheckInWeekday.storageKey:
            weeklyCheckInWeekdayRaw = CheckInWeekday(rawValue: Int(value) ?? CheckInWeekday.sunday.rawValue)?.rawValue ?? CheckInWeekday.sunday.rawValue
        default:
            break
        }
    }
}
