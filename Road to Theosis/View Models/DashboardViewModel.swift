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
        updateItem(itemID, delta: 0.12)
        activeStreak += 1
        dailyCheckIns += 1
        prayerMinutes += 2
    }

    mutating func resetItem(_ itemID: SinCategory.ID) {
        updateItem(itemID, delta: -0.08)
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
        let elapsedDays = max(days, 0)
        guard elapsedDays > 0 else { return }

        for sectionIndex in sections.indices {
            for itemIndex in sections[sectionIndex].items.indices {
                let currentProgress = sections[sectionIndex].items[itemIndex].progress
                guard currentProgress < 1 else { continue }

                let recoveryDelta = dailyRecoveryDelta(for: currentProgress, elapsedDays: elapsedDays)
                sections[sectionIndex].items[itemIndex].progress = clampedProgress(currentProgress + recoveryDelta)
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
            updateLoggedSin(entry, delta: 0.12)
        case .loss:
            updateLoggedSin(entry, delta: -0.08)
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

    private func dailyRecoveryDelta(for progress: Double, elapsedDays: Int) -> Double {
        let remainingPurity = max(0, 1 - progress)
        let dailyRecoveryRate = 0.012
        return remainingPurity * (1 - pow(1 - dailyRecoveryRate, Double(elapsedDays)))
    }

    private func clampedProgress(_ progress: Double) -> Double {
        min(1, max(0, progress))
    }
}
