import SwiftUI

struct ConnectedSinReference: Codable, Hashable, Identifiable {
    let sectionTitle: String
    let sinTitle: String

    var id: String {
        "\(sectionTitle)|\(sinTitle)"
    }

    var displayTitle: String {
        "\(sectionTitle) / \(sinTitle)"
    }

    var resolvedIconName: String? {
        SinCategory.sample
            .first(where: { $0.title == sectionTitle })?
            .items.first(where: { $0.title == sinTitle })?
            .icon
    }

    static func makeAllReferences(in sections: [SinSection] = SinCategory.sample) -> [ConnectedSinReference] {
        sections.flatMap { section in
            section.items.map { item in
                ConnectedSinReference(sectionTitle: section.title, sinTitle: item.title)
            }
        }
    }

    static func ordered(_ references: some Sequence<ConnectedSinReference>, in sections: [SinSection] = SinCategory.sample) -> [ConnectedSinReference] {
        let sectionOrder = Dictionary(uniqueKeysWithValues: sections.enumerated().map { ($1.title, $0) })
        let itemOrder = Dictionary(uniqueKeysWithValues: sections.flatMap { section in
            section.items.enumerated().map { itemIndex, item in
                ("\(section.title)|\(item.title)", itemIndex)
            }
        })

        return references.sorted { lhs, rhs in
            let lhsSection = sectionOrder[lhs.sectionTitle] ?? .max
            let rhsSection = sectionOrder[rhs.sectionTitle] ?? .max

            if lhsSection != rhsSection {
                return lhsSection < rhsSection
            }

            let lhsItem = itemOrder[lhs.id] ?? .max
            let rhsItem = itemOrder[rhs.id] ?? .max
            if lhsItem != rhsItem {
                return lhsItem < rhsItem
            }

            return lhs.displayTitle < rhs.displayTitle
        }
    }
}
