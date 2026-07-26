import Foundation
import SwiftUI

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

    var totalItems: Int {
        sections.reduce(0) { $0 + $1.itemCount }
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

    mutating func markGeneralVictory() {
        activeStreak += 1
        dailyCheckIns += 1
        prayerMinutes += 3
    }

    mutating func noteTemptation() {
        if let firstItemID = sections.first?.items.first?.id {
            updateItem(firstItemID, delta: 0.06)
        }
        prayerMinutes += 1
    }

    mutating func record(_ entry: LogEntry) {
        dailyCheckIns += 1
        prayerMinutes += max(entry.prayerMinutes, 0)

        switch entry.kind {
        case .prayer:
            break
        case .quickPrayer:
            prayerMinutes += max(entry.prayerMinutes, 1)
            dailyCheckIns += 1
        case .victory:
            activeStreak += 1
            if let sinTitle = entry.sinTitle {
                updateItem(named: sinTitle, inSection: entry.sectionTitle, delta: 0.12)
            } else {
                updateFirstItem(in: entry.sectionTitle, delta: 0.12)
            }
        case .loss:
            if let sinTitle = entry.sinTitle {
                updateItem(named: sinTitle, inSection: entry.sectionTitle, delta: -0.08)
            } else {
                updateFirstItem(in: entry.sectionTitle, delta: -0.08)
            }
        case .note:
            break
        }
    }

    private mutating func updateItem(_ itemID: SinCategory.ID, delta: Double) {
        for sectionIndex in sections.indices {
            if let itemIndex = sections[sectionIndex].items.firstIndex(where: { $0.id == itemID }) {
                sections[sectionIndex].items[itemIndex].progress = min(1, max(0, sections[sectionIndex].items[itemIndex].progress + delta))
                return
            }
        }
    }

    private mutating func updateFirstItem(in sectionTitle: String, delta: Double) {
        guard let sectionIndex = sections.firstIndex(where: { $0.title == sectionTitle }) else {
            return
        }

        guard let itemIndex = sections[sectionIndex].items.indices.first else {
            return
        }

        sections[sectionIndex].items[itemIndex].progress = min(1, max(0, sections[sectionIndex].items[itemIndex].progress + delta))
    }

    private mutating func updateItem(named itemTitle: String, inSection sectionTitle: String, delta: Double) {
        guard let sectionIndex = sections.firstIndex(where: { $0.title == sectionTitle }) else {
            updateFirstItem(in: sectionTitle, delta: delta)
            return
        }

        if let itemIndex = sections[sectionIndex].items.firstIndex(where: { $0.title == itemTitle }) {
            sections[sectionIndex].items[itemIndex].progress = min(1, max(0, sections[sectionIndex].items[itemIndex].progress + delta))
        } else {
            updateFirstItem(in: sectionTitle, delta: delta)
        }
    }
}
