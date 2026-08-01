import Foundation

struct DashboardViewModel {
    var sections: [SinSection] = SinCategory.sample
    var dailyCheckIns = 12
    var activeStreak = 18
    var prayerMinutes = 24

    var totalProgress: Double {
        let allItems = sections.flatMap { $0.items }
        guard !allItems.isEmpty else { return 0 }

        let total = allItems.reduce(0.0) { $0 + $1.progress }
        return total / Double(allItems.count)
    }

    mutating func markVictory(in itemID: SinCategory.ID) {
        activeStreak += 1
        dailyCheckIns += 1
        prayerMinutes += 2
    }

    mutating func resetItem(_ itemID: SinCategory.ID) {
        setProgress(0.10, for: itemID)
    }

    mutating func setProgress(_ progress: Double, for itemID: SinCategory.ID) {
        for sectionIndex in sections.indices {
            guard let itemIndex = sections[sectionIndex].items.firstIndex(where: { $0.id == itemID }) else {
                continue
            }

            sections[sectionIndex].items[itemIndex].progress = clampedProgress(progress)
            return
        }
    }

    mutating func advanceDailyProgress(days: Int = 1) {
        // Kept as a compatibility no-op. Purity now comes from log history.
    }

    mutating func recalculatePurity(from entries: [LogEntry], now: Date = .now) {
        let calendar = Calendar.current
        let windowStart = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let pureStart = calendar.date(byAdding: .day, value: -90, to: now) ?? now

        for sectionIndex in sections.indices {
            for itemIndex in sections[sectionIndex].items.indices {
                let sectionTitle = sections[sectionIndex].title
                let sinTitle = sections[sectionIndex].items[itemIndex].title
                let sinEntries = entries.filter { entry in
                    entry.sectionTitle == sectionTitle &&
                    entry.sinTitle == sinTitle &&
                    entry.occurredAt <= now
                }
                let lossEntries = sinEntries.filter { $0.kind == .loss }
                let recentLossCount = lossEntries.filter { $0.occurredAt >= windowStart }.count
                let recentResistanceCount = sinEntries.filter { entry in
                    entry.kind == .victory && entry.occurredAt >= windowStart
                }.count

                sections[sectionIndex].items[itemIndex].recentResistanceCount = recentResistanceCount

                guard let latestLossDate = lossEntries.map(\.occurredAt).max() else {
                    continue
                }

                let lossPressure = effectiveLossPressure(recentLossCount: recentLossCount, recentResistanceCount: recentResistanceCount)
                let purity = purityScore(lossPressure: lossPressure, latestLossDate: latestLossDate, pureStart: pureStart)
                sections[sectionIndex].items[itemIndex].progress = purity
            }
        }
    }

    mutating func record(_ entry: LogEntry) {
        dailyCheckIns += 1
        prayerMinutes += max(entry.prayerMinutes, 0)

        switch entry.kind {
        case .prayer, .note:
            break
        case .quickPrayer:
            prayerMinutes += max(entry.prayerMinutes, 1)
            dailyCheckIns += 1
        case .victory:
            activeStreak += 1
        case .loss:
            activeStreak = 0
        case .progressUpdate, .sliderProgressUpdate:
            updateLoggedSinProgress(entry)
        }
    }

    private mutating func updateLoggedSin(_ entry: LogEntry, delta: Double) {
        if let sinTitle = entry.sinTitle {
            updateItem(named: sinTitle, inSection: entry.sectionTitle, delta: delta)
        } else {
            updateFirstItem(in: entry.sectionTitle, delta: delta)
        }
    }

    private mutating func updateLoggedSinProgress(_ entry: LogEntry) {
        guard let progressPercentage = entry.progressPercentage else {
            return
        }

        let progress = Double(progressPercentage) / 100
        if let sinTitle = entry.sinTitle {
            setProgress(progress, named: sinTitle, inSection: entry.sectionTitle)
        } else {
            setFirstItemProgress(progress, in: entry.sectionTitle)
        }
    }

    private mutating func updateItem(_ itemID: SinCategory.ID, delta: Double) {
        for sectionIndex in sections.indices {
            guard let itemIndex = sections[sectionIndex].items.firstIndex(where: { $0.id == itemID }) else {
                continue
            }

            updateItem(at: itemIndex, in: sectionIndex, delta: delta)
            return
        }
    }

    private mutating func updateItem(named itemTitle: String, inSection sectionTitle: String, delta: Double) {
        guard let sectionIndex = sections.firstIndex(where: { $0.title == sectionTitle }) else {
            updateFirstItem(in: sectionTitle, delta: delta)
            return
        }

        guard let itemIndex = sections[sectionIndex].items.firstIndex(where: { $0.title == itemTitle }) else {
            updateFirstItem(in: sectionTitle, delta: delta)
            return
        }

        updateItem(at: itemIndex, in: sectionIndex, delta: delta)
    }

    private mutating func setProgress(_ progress: Double, named itemTitle: String, inSection sectionTitle: String) {
        guard let sectionIndex = sections.firstIndex(where: { $0.title == sectionTitle }) else {
            setFirstItemProgress(progress, in: sectionTitle)
            return
        }

        guard let itemIndex = sections[sectionIndex].items.firstIndex(where: { $0.title == itemTitle }) else {
            setFirstItemProgress(progress, in: sectionTitle)
            return
        }

        sections[sectionIndex].items[itemIndex].progress = clampedProgress(progress)
    }

    private mutating func updateFirstItem(in sectionTitle: String, delta: Double) {
        guard let sectionIndex = sections.firstIndex(where: { $0.title == sectionTitle }),
              let itemIndex = sections[sectionIndex].items.indices.first else {
            return
        }

        updateItem(at: itemIndex, in: sectionIndex, delta: delta)
    }

    private mutating func setFirstItemProgress(_ progress: Double, in sectionTitle: String) {
        guard let sectionIndex = sections.firstIndex(where: { $0.title == sectionTitle }),
              let itemIndex = sections[sectionIndex].items.indices.first else {
            return
        }

        sections[sectionIndex].items[itemIndex].progress = clampedProgress(progress)
    }

    private mutating func updateItem(at itemIndex: Int, in sectionIndex: Int, delta: Double) {
        let currentProgress = sections[sectionIndex].items[itemIndex].progress
        sections[sectionIndex].items[itemIndex].progress = clampedProgress(currentProgress + delta)
    }

    private func effectiveLossPressure(recentLossCount: Int, recentResistanceCount: Int) -> Double {
        guard recentLossCount > 0 else { return 0 }

        let resistanceCredit = Double(recentResistanceCount) * 0.5
        let maxCredit = Double(recentLossCount) * 0.25
        return max(1, Double(recentLossCount) - min(resistanceCredit, maxCredit))
    }

    private func purityScore(lossPressure: Double, latestLossDate: Date, pureStart: Date) -> Double {
        switch lossPressure {
        case 22...:
            return 0.10
        case 14..<22:
            return 0.30
        case 8..<14:
            return 0.48
        case 4..<8:
            return 0.63
        case 2..<4:
            return 0.78
        case 1..<2:
            return 0.90
        default:
            return latestLossDate <= pureStart ? 1.0 : 0.97
        }
    }

    private func clampedProgress(_ progress: Double) -> Double {
        min(1, max(0, progress))
    }
}
