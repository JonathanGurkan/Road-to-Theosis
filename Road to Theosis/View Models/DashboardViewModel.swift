import Foundation

struct DashboardViewModel {
    var sections: [SinSection] = SinCategory.sample
    var dailyCheckIns = 12
    var activeStreak = 18
    var prayerMinutes = 24
    var overallResistanceCount = 0

    var totalProgress: Double {
        let allItems = sections.flatMap { $0.items }
        guard !allItems.isEmpty else { return 0 }

        let total = allItems.reduce(0.0) { $0 + $1.progress }
        return total / Double(allItems.count)
    }

    mutating func markVictory(in itemID: SinCategory.ID) {
        activeStreak += 1
        dailyCheckIns += 1
        overallResistanceCount += 1
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
        // Kept as a compatibility no-op. Purity now comes from log history and the selected strictness.
    }

    mutating func recalculatePurity(
        from entries: [LogEntry],
        now: Date = .now,
        strictness: PurityStrictness = .normal
    ) {
        overallResistanceCount = entries.filter { $0.kind == .victory && $0.occurredAt <= now }.count

        for sectionIndex in sections.indices {
            for itemIndex in sections[sectionIndex].items.indices {
                let sectionTitle = sections[sectionIndex].title
                let sinTitle = sections[sectionIndex].items[itemIndex].title
                let snapshot = PurityCalculator.snapshot(
                    sectionTitle: sectionTitle,
                    sinTitle: sinTitle,
                    entries: entries,
                    now: now,
                    strictness: strictness,
                    qualifiesForPrayerBoost: sections[sectionIndex].items[itemIndex].qualifiesForPrayerPurityBoost
                )

                sections[sectionIndex].items[itemIndex].progress = snapshot.progress
                sections[sectionIndex].items[itemIndex].recentResistanceCount = snapshot.recentResistanceCount
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
            overallResistanceCount += 1
        case .loss:
            activeStreak = 0
        case .progressUpdate, .sliderProgressUpdate:
            updateLoggedSinProgress(entry)
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

    private mutating func setFirstItemProgress(_ progress: Double, in sectionTitle: String) {
        guard let sectionIndex = sections.firstIndex(where: { $0.title == sectionTitle }),
              let itemIndex = sections[sectionIndex].items.indices.first else {
            return
        }

        sections[sectionIndex].items[itemIndex].progress = clampedProgress(progress)
    }

    private func clampedProgress(_ progress: Double) -> Double {
        min(1, max(0, progress))
    }
}
