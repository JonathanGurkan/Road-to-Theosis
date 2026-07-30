import SwiftUI

struct HomeCardDropDelegate: DropDelegate {
    let targetID: HomeScreenCardID
    let targetSize: CGSize
    @Binding var draggingID: HomeScreenCardID?
    let move: (HomeScreenCardID, HomeScreenCardID, Bool) -> Void

    func dropEntered(info: DropInfo) {
        guard let sourceID = draggingID, sourceID != targetID else {
            return
        }

        let insertAfter = info.location.y > targetSize.height / 2 || info.location.x > targetSize.width / 2
        move(sourceID, targetID, insertAfter)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingID = nil
        return true
    }
}

struct HomeScreenGridWidthUnitsKey: LayoutValueKey {
    nonisolated static let defaultValue = 4
}

struct HomeScreenGridHeightUnitsKey: LayoutValueKey {
    nonisolated static let defaultValue = 2
}

struct HomeScreenGridUsesFixedHeightKey: LayoutValueKey {
    nonisolated static let defaultValue = true
}

struct HomeScreenGridPlacement {
    let index: Int
    let x: Int
    let y: Int
    let width: Int
    let height: Int
}

struct HomeScreenGridLayout: Layout {
    static let defaultHorizontalSpacing: CGFloat = 8
    static let defaultVerticalSpacing: CGFloat = 8

    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let placements = resolvedPlacements(for: subviews, totalWidth: width)
        let totalHeight = placements.map { $0.frame.maxY }.max() ?? 0

        return CGSize(width: width, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let placements = resolvedPlacements(for: subviews, totalWidth: bounds.width)

        for placement in placements {
            subviews[placement.index].place(
                at: CGPoint(x: bounds.minX + placement.frame.minX, y: bounds.minY + placement.frame.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: placement.frame.width, height: placement.frame.height)
            )
        }
    }

    static func gridPlacements(for cards: [HomeScreenCardConfiguration]) -> [HomeScreenGridPlacement] {
        placeItems(cards.indices.map { index in
            let card = cards[index]
            return (
                index: index,
                width: card.id.supportsResizing ? card.size.widthUnits : 4,
                height: card.id.supportsResizing && card.size.usesFixedGridHeight ? card.size.heightUnits : 2
            )
        })
    }

    private func resolvedPlacements(for subviews: Subviews, totalWidth: CGFloat) -> [(index: Int, frame: CGRect)] {
        var occupied = Array(repeating: Array(repeating: false, count: 4), count: max(1, subviews.count * 2))
        var placements: [(index: Int, frame: CGRect)] = []
        var blockYOffset: CGFloat = 0

        for index in subviews.indices {
            let widthUnits = min(max(subviews[index][HomeScreenGridWidthUnitsKey.self], 1), 4)
            let width = length(for: widthUnits, totalWidth: totalWidth, spacing: horizontalSpacing)

            if subviews[index][HomeScreenGridUsesFixedHeightKey.self] {
                let heightUnits = max(subviews[index][HomeScreenGridHeightUnitsKey.self], 1)
                let origin = Self.firstAvailableOrigin(width: widthUnits, height: heightUnits, occupied: &occupied)
                Self.markOccupied(origin: origin, width: widthUnits, height: heightUnits, occupied: &occupied)

                placements.append((
                    index: index,
                    frame: CGRect(
                        x: offset(for: origin.x, totalWidth: totalWidth, spacing: horizontalSpacing),
                        y: blockYOffset + offset(for: origin.y, totalWidth: totalWidth, spacing: verticalSpacing),
                        width: width,
                        height: length(for: heightUnits, totalWidth: totalWidth, spacing: verticalSpacing)
                    )
                ))
            } else {
                let occupiedRows = occupied.lastIndex { row in row.contains(true) }.map { $0 + 1 } ?? 0
                let y = blockYOffset + length(for: occupiedRows, totalWidth: totalWidth, spacing: verticalSpacing) + (occupiedRows > 0 ? verticalSpacing : 0)
                let height = subviews[index].sizeThatFits(ProposedViewSize(width: width, height: nil)).height
                placements.append((index: index, frame: CGRect(x: 0, y: y, width: width, height: height)))

                blockYOffset = y + height + verticalSpacing
                occupied = Array(repeating: Array(repeating: false, count: 4), count: max(1, subviews.count * 2))
            }
        }

        return placements
    }

    private static func placeItems(_ items: [(index: Int, width: Int, height: Int)]) -> [HomeScreenGridPlacement] {
        var occupied = Array(repeating: Array(repeating: false, count: 4), count: max(1, items.count * 2))
        var placements: [HomeScreenGridPlacement] = []

        for item in items {
            let width = min(max(item.width, 1), 4)
            let height = max(item.height, 1)
            let origin = firstAvailableOrigin(width: width, height: height, occupied: &occupied)
            markOccupied(origin: origin, width: width, height: height, occupied: &occupied)
            placements.append(HomeScreenGridPlacement(index: item.index, x: origin.x, y: origin.y, width: width, height: height))
        }

        return placements
    }

    private static func firstAvailableOrigin(width: Int, height: Int, occupied: inout [[Bool]]) -> (x: Int, y: Int) {
        var y = 0

        while true {
            ensureRows(upTo: y + height, occupied: &occupied)

            for x in 0...(4 - width) {
                if isAvailable(x: x, y: y, width: width, height: height, occupied: occupied) {
                    return (x, y)
                }
            }

            y += 1
        }
    }

    private static func isAvailable(x: Int, y: Int, width: Int, height: Int, occupied: [[Bool]]) -> Bool {
        for row in y..<(y + height) {
            for column in x..<(x + width) where occupied[row][column] {
                return false
            }
        }

        return true
    }

    private static func markOccupied(origin: (x: Int, y: Int), width: Int, height: Int, occupied: inout [[Bool]]) {
        ensureRows(upTo: origin.y + height, occupied: &occupied)

        for row in origin.y..<(origin.y + height) {
            for column in origin.x..<(origin.x + width) {
                occupied[row][column] = true
            }
        }
    }

    private static func ensureRows(upTo rowCount: Int, occupied: inout [[Bool]]) {
        while occupied.count < rowCount {
            occupied.append(Array(repeating: false, count: 4))
        }
    }

    private func length(for units: Int, totalWidth: CGFloat, spacing: CGFloat) -> CGFloat {
        let clampedUnits = max(units, 0)
        guard clampedUnits > 0 else { return 0 }

        let columnWidth = max(0, (totalWidth - horizontalSpacing * 3) / 4)
        return columnWidth * CGFloat(clampedUnits) + spacing * CGFloat(clampedUnits - 1)
    }

    private func offset(for units: Int, totalWidth: CGFloat, spacing: CGFloat) -> CGFloat {
        guard units > 0 else { return 0 }

        let columnWidth = max(0, (totalWidth - horizontalSpacing * 3) / 4)
        return (columnWidth + spacing) * CGFloat(units)
    }
}

extension HomeScreenCardSize {
    var usesFixedGridHeight: Bool {
        switch self {
        case .minimal, .compact:
            return true
        case .standard:
            return false
        }
    }

    var widthUnits: Int {
        switch self {
        case .minimal:
            return 2
        case .compact:
            return 2
        case .standard:
            return 4
        }
    }

    var heightUnits: Int {
        switch self {
        case .minimal:
            return 1
        case .compact, .standard:
            return 2
        }
    }
}

extension HeadwayView {
    static let activityTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    static let subtitleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
}
