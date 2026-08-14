import Foundation

enum AppPreferenceKey: String, CaseIterable {
    case backgroundTheme
    case checkInEnabledQuestionIDs
    case compactSinRows
    case customDefenseVersesBySin
    case enableVerseInventory
    case focusSliderStyle
    case focusedSinReferences
    case greetingWeatherBreezyThresholdKilometersPerHour
    case greetingWeatherColdThresholdCelsius
    case greetingWeatherWarmThresholdCelsius
    case hasSeenWelcome
    case homeScreenLayout
    case isGreetingWeatherEnabled
    case isWeeklyCheckInReminderEnabled
    case isICloudSyncEnabled
    case isPrayerTimingEnabled
    case keepScreenAwakeDuringPrayer
    case lastWeeklyCheckInReminderDay
    case prayerTimerCountingMode
    case purityStrictness
    case showRecentActivity
    case showVerseApplications
    case timelineRange
    case usesFocusProgressSliders
    case weeklyCheckInHour
    case weeklyCheckInMinute
    case weeklyCheckInSnoozedUntil
    case weeklyCheckInWeekday

    var storageKey: String { rawValue }

    func legacyStoredValue(userDefaults: UserDefaults = .standard) -> String? {
        let key = storageKey

        switch self {
        case .backgroundTheme,
             .checkInEnabledQuestionIDs,
             .customDefenseVersesBySin,
             .focusSliderStyle,
             .focusedSinReferences,
             .homeScreenLayout,
             .lastWeeklyCheckInReminderDay,
             .prayerTimerCountingMode,
             .purityStrictness,
             .timelineRange:
            return userDefaults.string(forKey: key)
        case .compactSinRows,
             .enableVerseInventory,
             .hasSeenWelcome,
             .isGreetingWeatherEnabled,
             .isPrayerTimingEnabled,
             .isWeeklyCheckInReminderEnabled,
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
        case .weeklyCheckInHour,
             .weeklyCheckInMinute,
             .weeklyCheckInSnoozedUntil,
             .weeklyCheckInWeekday:
            guard userDefaults.object(forKey: key) != nil else { return nil }
            return String(userDefaults.integer(forKey: key))
        }
    }
}
