import Foundation

enum AppPreferenceKey: String, CaseIterable {
    case backgroundTheme
    case compactSinRows
    case customDefenseVersesBySin
    case enableVerseInventory
    case focusSliderStyle
    case focusedSinReferences
    case hasSeenWelcome
    case greetingWeatherBreezyThresholdKilometersPerHour
    case greetingWeatherColdThresholdCelsius
    case greetingWeatherWarmThresholdCelsius
    case homeScreenLayout
    case isGreetingWeatherEnabled
    case isICloudSyncEnabled
    case isPrayerTimingEnabled
    case keepScreenAwakeDuringPrayer
    case prayerTimerCountingMode
    case purityStrictness
    case timelineRange
    case showRecentActivity
    case showVerseApplications
    case usesFocusProgressSliders

    var storageKey: String { rawValue }

    func legacyStoredValue(userDefaults: UserDefaults = .standard) -> String? {
        let key = storageKey

        switch self {
        case .backgroundTheme,
             .customDefenseVersesBySin,
             .focusSliderStyle,
             .focusedSinReferences,
             .homeScreenLayout,
             .prayerTimerCountingMode,
             .purityStrictness,
             .timelineRange:
            return userDefaults.string(forKey: key)
        case .compactSinRows,
             .enableVerseInventory,
             .hasSeenWelcome,
             .isGreetingWeatherEnabled,
             .isPrayerTimingEnabled,
             .keepScreenAwakeDuringPrayer,
             .showRecentActivity,
             .showVerseApplications,
             .usesFocusProgressSliders:
            guard userDefaults.object(forKey: key) != nil else { return nil }
            return String(userDefaults.bool(forKey: key))
        case .isICloudSyncEnabled:
            guard userDefaults.object(forKey: AppPersistence.legacyICloudSyncEnabledKey) != nil else { return nil }
            return String(userDefaults.bool(forKey: AppPersistence.legacyICloudSyncEnabledKey))
        case .greetingWeatherBreezyThresholdKilometersPerHour,
             .greetingWeatherColdThresholdCelsius,
             .greetingWeatherWarmThresholdCelsius:
            guard userDefaults.object(forKey: key) != nil else { return nil }
            return String(userDefaults.double(forKey: key))
        }
    }
}
