import SwiftUI

struct LogEntry: Codable, Identifiable, Equatable {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case prayer
        case quickPrayer
        case victory
        case loss
        case progressUpdate
        case sliderProgressUpdate
        case checkIn
        case note

        var id: String { rawValue }

        var title: String {
            switch self {
            case .prayer:
                return "Prayer"
            case .quickPrayer:
                return "Quick Prayer"
            case .victory:
                return "Resistance"
            case .loss:
                return "Loss"
            case .progressUpdate:
                return "Progress Set"
            case .sliderProgressUpdate:
                return "Purity Adjusted"
            case .checkIn:
                return "Check-in"
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
            case .progressUpdate:
                return "slider.horizontal.3"
            case .sliderProgressUpdate:
                return "slider.horizontal.below.rectangle"
            case .checkIn:
                return "checklist"
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
            case .progressUpdate:
                return .blue
            case .sliderProgressUpdate:
                return .indigo
            case .checkIn:
                return .orange
            case .note:
                return .blue
            }
        }
    }

    let id: UUID
    let kind: Kind
    let sectionTitle: String
    let sinTitle: String?
    let note: String
    let prayerMinutes: Int
    let prayerDurationSeconds: Int
    let progressPercentage: Int?
    let checkInRecordJSON: String?
    let occurredAt: Date

    init(
        id: UUID = UUID(),
        kind: Kind,
        sectionTitle: String,
        sinTitle: String?,
        note: String,
        prayerMinutes: Int,
        prayerDurationSeconds: Int? = nil,
        progressPercentage: Int? = nil,
        checkInRecordJSON: String? = nil,
        occurredAt: Date
    ) {
        self.id = id
        self.kind = kind
        self.sectionTitle = sectionTitle
        self.sinTitle = sinTitle
        self.note = note
        self.prayerMinutes = prayerMinutes
        self.prayerDurationSeconds = prayerDurationSeconds ?? max(prayerMinutes, 0) * 60
        self.progressPercentage = progressPercentage
        self.checkInRecordJSON = checkInRecordJSON
        self.occurredAt = occurredAt
    }

    var prayerDurationText: String {
        Self.formatPrayerDuration(seconds: prayerDurationSeconds)
    }

    var checkInRecord: CheckInRecord? {
        guard let checkInRecordJSON,
              let data = checkInRecordJSON.data(using: .utf8) else {
            return nil
        }

        return try? JSONDecoder().decode(CheckInRecord.self, from: data)
    }

    static func formatPrayerDuration(seconds: Int) -> String {
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
