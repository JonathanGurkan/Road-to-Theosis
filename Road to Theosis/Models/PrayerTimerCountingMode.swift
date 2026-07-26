import Foundation

enum PrayerTimerCountingMode: String, CaseIterable, Identifiable {
    case foreground
    case background

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .foreground:
            return "Foreground only"
        case .background:
            return "Count in background"
        }
    }

    var description: String {
        switch self {
        case .foreground:
            return "Counts while the timer screen is active."
        case .background:
            return "Counts elapsed time even after the app moves to the background."
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
