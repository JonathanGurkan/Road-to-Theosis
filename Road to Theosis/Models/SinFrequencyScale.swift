import SwiftUI

struct SinFrequencyLevel: Identifiable {
    let id: String
    let title: String
    let detail: String
    let rangeText: String
}

enum SinFrequencyScale {
    static let levels: [SinFrequencyLevel] = [
        SinFrequencyLevel(id: "none", title: "Not active", detail: "No recent falls", rangeText: "0%"),
        SinFrequencyLevel(id: "rare", title: "Rare", detail: "Less than monthly", rangeText: "1-15%"),
        SinFrequencyLevel(id: "occasional", title: "Occasional", detail: "Monthly pattern", rangeText: "16-30%"),
        SinFrequencyLevel(id: "repeatedMonthly", title: "Repeated monthly", detail: "Several times a month", rangeText: "31-45%"),
        SinFrequencyLevel(id: "weekly", title: "Weekly", detail: "About once a week", rangeText: "46-60%"),
        SinFrequencyLevel(id: "frequent", title: "Frequent", detail: "Several times a week", rangeText: "61-80%"),
        SinFrequencyLevel(id: "daily", title: "Daily", detail: "Daily or near daily", rangeText: "81-100%")
    ]

    static let milestoneProgresses: [Double] = [0, 0.15, 0.30, 0.45, 0.60, 0.80, 1]

    static func percentage(for progress: Double) -> Int {
        Int((min(max(progress, 0), 1) * 100).rounded())
    }

    static func level(for percentage: Int) -> SinFrequencyLevel {
        switch min(max(percentage, 0), 100) {
        case 0:
            return levels[0]
        case 1...15:
            return levels[1]
        case 16...30:
            return levels[2]
        case 31...45:
            return levels[3]
        case 46...60:
            return levels[4]
        case 61...80:
            return levels[5]
        default:
            return levels[6]
        }
    }

    static func level(for progress: Double) -> SinFrequencyLevel {
        level(for: percentage(for: progress))
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
            return "Smooth track with the frequency label below."
        case .marked:
            return "Adds frequency indicators along the track."
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
        case .clean, .marked:
            return 30
        case .compact:
            return 22
        }
    }

    var showsMilestones: Bool {
        self == .marked
    }

    var showsLegend: Bool {
        self != .compact
    }
}
