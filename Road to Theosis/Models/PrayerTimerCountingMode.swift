import Foundation

enum PrayerTimerCountingMode: String, CaseIterable, Identifiable {
    case foreground
    case background

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .foreground:
            return "Show timer"
        case .background:
            return "Start in background"
        }
    }

    var description: String {
        switch self {
        case .foreground:
            return "Counts while the timer screen is active."
        case .background:
            return "Counts elapsed time without a visual timer screen. The timer will continue to count even after the app is closed to the background"
        }
    }

    var readyInstruction: String {
        switch self {
        case .foreground:
            return "Tap start, then leave the phone alone and pray."
        case .background:
            return "Tap start, then you can lock the phone or leave the app while you pray."
        }
    }

    var runningInstruction: String {
        switch self {
        case .foreground:
            return "Keep your attention on prayer, not the clock."
        case .background:
            return "The timer will use elapsed time when you return and stop the session."
        }
    }
}
