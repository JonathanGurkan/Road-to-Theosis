import SwiftUI

struct PuritySnapshot {
    let progress: Double
    let recentLossCount: Int
    let recentResistanceCount: Int
    let cleanDayCount: Int?
    let latestLossDate: Date?
    let latestBaselineDate: Date?
}

enum PurityStrictness: String, CaseIterable, Identifiable {
    case veryLoose
    case loose
    case normal
    case strict

    static let storageKey = "purityStrictness"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .veryLoose:
            return "Very Loose"
        case .loose:
            return "Loose"
        case .normal:
            return "Normal"
        case .strict:
            return "Strict"
        }
    }

    var historyDays: Int {
        switch self {
        case .veryLoose:
            return 7
        case .loose:
            return 14
        case .normal:
            return 30
        case .strict:
            return 90
        }
    }

    var pureAfterDays: Int {
        switch self {
        case .veryLoose:
            return 14
        case .loose:
            return 30
        case .normal:
            return 90
        case .strict:
            return 180
        }
    }

    var subtitle: String {
        "Uses \(historyDays) days of history; Pure after \(pureAfterDays) clean days."
    }
}

enum PurityCalculator {
    static func snapshot(
        sectionTitle: String,
        sinTitle: String,
        entries: [LogEntry],
        now: Date,
        strictness: PurityStrictness,
        calendar: Calendar = .current
    ) -> PuritySnapshot {
        let targetEntries = entries.filter { entry in
            entry.sectionTitle == sectionTitle &&
            entry.sinTitle == sinTitle &&
            entry.occurredAt <= now
        }

        guard !targetEntries.isEmpty else {
            return PuritySnapshot(
                progress: 1,
                recentLossCount: 0,
                recentResistanceCount: 0,
                cleanDayCount: nil,
                latestLossDate: nil,
                latestBaselineDate: nil
            )
        }

        let latestBaseline = targetEntries
            .filter { ($0.kind == .progressUpdate || $0.kind == .sliderProgressUpdate) && $0.progressPercentage != nil }
            .max { $0.occurredAt < $1.occurredAt }
        let baselineProgress = latestBaseline
            .flatMap { $0.progressPercentage }
            .map { clamped(Double($0) / 100) }
        let baselineDate = latestBaseline?.occurredAt
        let calculationStart = baselineDate ?? .distantPast
        let historyStart = calendar.date(byAdding: .day, value: -strictness.historyDays, to: now) ?? now
        let activeStart = max(historyStart, calculationStart)

        let lossEntries = targetEntries.filter { entry in
            entry.kind == .loss && entry.occurredAt >= calculationStart
        }
        let recentLossCount = lossEntries.filter { $0.occurredAt >= activeStart }.count
        let recentResistanceCount = targetEntries.filter { entry in
            entry.kind == .victory &&
            entry.occurredAt >= activeStart &&
            entry.occurredAt <= now
        }.count
        let latestLossDate = lossEntries.map(\.occurredAt).max()
        let cleanAnchor = latestLossDate ?? baselineDate
        let cleanDayCount = cleanAnchor.map { max(0, calendar.dateComponents([.day], from: $0, to: now).day ?? 0) }

        let calculatedProgress: Double
        if recentLossCount > 0 {
            let weeklyLossRate = Double(recentLossCount) / Double(strictness.historyDays) * 7
            let frequencyProgress = progress(forWeeklyLossRate: weeklyLossRate)
            if let baselineProgress {
                calculatedProgress = clamped(baselineProgress * frequencyProgress)
            } else {
                calculatedProgress = frequencyProgress
            }
        } else if let cleanDayCount {
            let cleanFraction = min(1, Double(cleanDayCount) / Double(strictness.pureAfterDays))
            if let baselineProgress, latestLossDate == nil {
                calculatedProgress = clamped(baselineProgress + (1 - baselineProgress) * cleanFraction)
            } else {
                calculatedProgress = clamped(0.96 + 0.04 * cleanFraction)
            }
        } else {
            calculatedProgress = baselineProgress ?? 1
        }

        return PuritySnapshot(
            progress: calculatedProgress,
            recentLossCount: recentLossCount,
            recentResistanceCount: recentResistanceCount,
            cleanDayCount: cleanDayCount,
            latestLossDate: latestLossDate,
            latestBaselineDate: baselineDate
        )
    }

    static func progress(forWeeklyLossRate weeklyLossRate: Double) -> Double {
        switch weeklyLossRate {
        case 5.13...:
            return 0.10
        case 3.27..<5.13:
            return 0.30
        case 1.87..<3.27:
            return 0.48
        case 0.93..<1.87:
            return 0.63
        case 0.47..<0.93:
            return 0.78
        case 0.01..<0.47:
            return 0.90
        default:
            return 1
        }
    }

    private static func clamped(_ progress: Double) -> Double {
        min(1, max(0, progress))
    }
}

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
        SinFrequencyLevel(id: "severalWeekly", title: "Often", detail: "2-4 times weekly", rangeText: "41-55%"),
        SinFrequencyLevel(id: "weekly", title: "Weekly", detail: "about once weekly", rangeText: "56-70%"),
        SinFrequencyLevel(id: "repeatedMonthly", title: "Occasional", detail: "2-3 times monthly", rangeText: "71-85%"),
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
