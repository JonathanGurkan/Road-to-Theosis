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
    let occurredAt: Date
}
