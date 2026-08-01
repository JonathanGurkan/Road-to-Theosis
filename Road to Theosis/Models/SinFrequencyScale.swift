import SwiftUI

struct SinFrequencyLevel: Identifiable {
    let id: String
    let title: String
    let detail: String
    let rangeText: String
}

enum SinFrequencyScale {
    static let levels: [SinFrequencyLevel] = [
        SinFrequencyLevel(id: "rockBottom", title: "Rock bottom", detail: "daily or near daily", rangeText: "0-20%"),
        SinFrequencyLevel(id: "daily", title: "Daily", detail: "daily or near daily", rangeText: "21-40%"),
        SinFrequencyLevel(id: "severalWeekly", title: "Several times weekly", detail: "2-4 times weekly", rangeText: "41-55%"),
        SinFrequencyLevel(id: "weekly", title: "Weekly", detail: "about once weekly", rangeText: "56-70%"),
        SinFrequencyLevel(id: "repeatedMonthly", title: "Repeated monthly", detail: "2-3 times monthly", rangeText: "71-85%"),
        SinFrequencyLevel(id: "monthly", title: "Monthly", detail: "about once a month", rangeText: "86-95%"),
        SinFrequencyLevel(id: "rare", title: "Rare", detail: "less than monthly", rangeText: "96-99%"),
        SinFrequencyLevel(id: "pure", title: "Pure", detail: "not recently", rangeText: "100%")
    ]

    static let milestoneProgresses: [Double] = [0, 0.20, 0.40, 0.55, 0.70, 0.85, 0.95, 1]

    static func percentage(for progress: Double) -> Int {
        Int((min(max(progress, 0), 1) * 100).rounded())
    }

    static func level(for percentage: Int) -> SinFrequencyLevel {
        switch min(max(percentage, 0), 100) {
        case 0...20:
            return levels[0]
        case 21...40:
            return levels[1]
        case 41...55:
            return levels[2]
        case 56...70:
            return levels[3]
        case 71...85:
            return levels[4]
        case 86...95:
            return levels[5]
        case 96...99:
            return levels[6]
        default:
            return levels[7]
        }
    }

    static func level(for progress: Double) -> SinFrequencyLevel {
        level(for: percentage(for: progress))
    }

    static func nextMilestone(after progress: Double) -> Double? {
        let clampedProgress = min(max(progress, 0), 1)
        return milestoneProgresses.first { $0 > clampedProgress }
    }

    static func nextLevel(after progress: Double) -> SinFrequencyLevel? {
        guard let milestone = nextMilestone(after: progress) else { return nil }
        let nextPercentage = min(100, Int((milestone * 100).rounded()) + 1)
        return level(for: nextPercentage)
    }

    static func label(for percentage: Int) -> String {
        "\(percentage)% \(level(for: percentage).title)"
    }

    static func label(for progress: Double) -> String {
        label(for: percentage(for: progress))
    }
}

enum FocusSliderStyle: String, CaseIterable, Identifiable {
    case clean
    case marked
    case compact

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clean:
            return "Clean"
        case .marked:
            return "Marked"
        case .compact:
            return "Compact"
        }
    }

    var subtitle: String {
        switch self {
        case .clean:
            return "Smooth track with subtle frequency indicators."
        case .marked:
            return "Uses slightly stronger frequency indicators beneath the slider."
        case .compact:
            return "Shorter control for a denser focus list."
        }
    }

    var trackHeight: CGFloat {
        switch self {
        case .clean, .marked:
            return 8
        case .compact:
            return 5
        }
    }

    var thumbSize: CGFloat {
        switch self {
        case .clean, .marked:
            return 24
        case .compact:
            return 18
        }
    }

    var controlHeight: CGFloat {
        switch self {
        case .clean:
            return 30
        case .marked:
            return 36
        case .compact:
            return 22
        }
    }

    var showsMilestones: Bool {
        self != .compact
    }

    var milestoneOpacity: (active: Double, inactive: Double) {
        switch self {
        case .marked:
            return (0.68, 0.30)
        case .clean:
            return (0.50, 0.20)
        case .compact:
            return (0, 0)
        }
    }

    var showsLegend: Bool {
        self != .compact
    }
}
