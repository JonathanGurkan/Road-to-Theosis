import SwiftUI

struct LogEntry: Identifiable {
    enum Kind: String, CaseIterable, Identifiable {
        case prayer
        case quickPrayer
        case victory
        case loss
        case note

        var id: String { rawValue }

        var title: String {
            switch self {
            case .prayer:
                return "Prayer"
            case .quickPrayer:
                return "Quick Prayer"
            case .victory:
                return "Victory"
            case .loss:
                return "Loss"
            case .note:
                return "Note"
            }
        }

        var symbolName: String {
            switch self {
            case .prayer:
                return "hands.sparkles.fill"
            case .quickPrayer:
                return "hands.sparkles"
            case .victory:
                return "checkmark.circle.fill"
            case .loss:
                return "xmark.circle.fill"
            case .note:
                return "text.quote"
            }
        }

        var tint: Color {
            switch self {
            case .prayer:
                return .cyan
            case .quickPrayer:
                return .teal
            case .victory:
                return .green
            case .loss:
                return .orange
            case .note:
                return .blue
            }
        }
    }

    let id = UUID()
    let kind: Kind
    let sectionTitle: String
    let sinTitle: String?
    let note: String
    let prayerMinutes: Int
    let prayerDurationSeconds: Int
    let occurredAt: Date

    init(
        kind: Kind,
        sectionTitle: String,
        sinTitle: String?,
        note: String,
        prayerMinutes: Int,
        prayerDurationSeconds: Int? = nil,
        occurredAt: Date
    ) {
        self.kind = kind
        self.sectionTitle = sectionTitle
        self.sinTitle = sinTitle
        self.note = note
        self.prayerMinutes = prayerMinutes
        self.prayerDurationSeconds = prayerDurationSeconds ?? max(prayerMinutes, 0) * 60
        self.occurredAt = occurredAt
    }

    var prayerDurationText: String {
        Self.formatPrayerDuration(seconds: prayerDurationSeconds)
    }

    private static func formatPrayerDuration(seconds: Int) -> String {
        let clampedSeconds = max(seconds, 0)

        guard clampedSeconds >= 60 else {
            return "\(max(clampedSeconds, 1))s"
        }

        let minutes = clampedSeconds / 60
        let remainingSeconds = clampedSeconds % 60

        guard remainingSeconds > 0 else {
            return "\(minutes)m"
        }

        return "\(minutes)m \(remainingSeconds)s"
    }
}
