import Foundation

enum AppPreferenceKey: String, CaseIterable {
    case backgroundTheme
    case compactSinRows
    case customDefenseVersesBySin
    case enableVerseInventory
    case focusSliderStyle
    case focusedSinReferences
    case hasSeenWelcome
    case homeScreenLayout
    case isPrayerTimingEnabled
    case keepScreenAwakeDuringPrayer
    case prayerTimerCountingMode
    case purityStrictness
    case showRecentActivity
    case showVerseApplications
    case usesFocusProgressSliders

    var storageKey: String { rawValue }
}
