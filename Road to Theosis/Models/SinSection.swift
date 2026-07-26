import SwiftUI

struct SinSection: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let tint: Color
    var isExpanded: Bool
    var items: [SinCategory]

    var averageProgress: Double {
        guard !items.isEmpty else { return 0 }
        let total = items.reduce(0.0) { $0 + $1.progress }
        return total / Double(items.count)
    }

    var itemCount: Int {
        items.count
    }

    static func section(title: String, subtitle: String, tint: Color, isExpanded: Bool = false, items: [SinCategory]) -> SinSection {
        let tintedItems = items.map { item in
            var tintedItem = item
            tintedItem.tint = tint
            return tintedItem
        }

        return SinSection(title: title, subtitle: subtitle, tint: tint, isExpanded: isExpanded, items: tintedItems)
    }
}
