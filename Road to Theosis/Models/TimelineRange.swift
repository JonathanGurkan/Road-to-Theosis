import Foundation

enum TimelineRange: String, CaseIterable, Identifiable {
    case week
    case month
    case ninetyDays
    case always

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week:
            return "Past Week"
        case .month:
            return "Past Month"
        case .ninetyDays:
            return "Past 90 Days"
        case .always:
            return "All Time"
        }
    }

    func contains(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        switch self {
        case .week:
            return date >= calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return date >= calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .ninetyDays:
            return date >= calendar.date(byAdding: .day, value: -90, to: now) ?? now
        case .always:
            return true
        }
    }
}
