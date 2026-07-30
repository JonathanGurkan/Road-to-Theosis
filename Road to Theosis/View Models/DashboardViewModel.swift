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
        }
    }

    private mutating func updateLoggedSin(_ entry: LogEntry, delta: Double) {
        if let sinTitle = entry.sinTitle {
            updateItem(named: sinTitle, inSection: entry.sectionTitle, delta: delta)
        } else {
            updateFirstItem(in: entry.sectionTitle, delta: delta)
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

    private mutating func updateFirstItem(in sectionTitle: String, delta: Double) {
        guard let sectionIndex = sections.firstIndex(where: { $0.title == sectionTitle }),
              let itemIndex = sections[sectionIndex].items.indices.first else {
            return
        }

        updateItem(at: itemIndex, in: sectionIndex, delta: delta)
    }

    private mutating func updateItem(at itemIndex: Int, in sectionIndex: Int, delta: Double) {
        let currentProgress = sections[sectionIndex].items[itemIndex].progress
        sections[sectionIndex].items[itemIndex].progress = clampedProgress(currentProgress + delta)
    }

    private func clampedProgress(_ progress: Double) -> Double {
        min(1, max(0, progress))
    }
}
