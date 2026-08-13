import Foundation

enum TimelineRange: String, CaseIterable, Identifiable {
    case always
    case ninetyDays
    case thirtyDays
    case fourteenDays
    case sevenDays

    var id: String { rawValue }

    var title: String {
        switch self {
        case .always:
            return "Always"
        case .ninetyDays:
            return "90 days"
        case .thirtyDays:
            return "30 days"
        case .fourteenDays:
            return "14 days"
        case .sevenDays:
            return "7 days"
        }
    }

    func cutoffDate(from date: Date, calendar: Calendar) -> Date? {
        switch self {
        case .always:
            return nil
        case .ninetyDays:
            return calendar.date(byAdding: .day, value: -90, to: date)
        case .thirtyDays:
            return calendar.date(byAdding: .day, value: -30, to: date)
        case .fourteenDays:
            return calendar.date(byAdding: .day, value: -14, to: date)
        case .sevenDays:
            return calendar.date(byAdding: .day, value: -7, to: date)
        }
    }
}
