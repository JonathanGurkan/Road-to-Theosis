import Foundation

struct HomeScreenLayout: Codable, Equatable {
    static let storageKey = "homeScreenLayout"

    var cards: [HomeScreenCardConfiguration]

    static let defaultValue = HomeScreenLayout(cards: [
        HomeScreenCardConfiguration(id: .greeting, size: .standard),
        HomeScreenCardConfiguration(id: .overview, size: .standard),
        HomeScreenCardConfiguration(id: .quickActions, size: .standard),
        HomeScreenCardConfiguration(id: .recentActivity, size: .standard),
        HomeScreenCardConfiguration(id: .focusAreas, size: .standard)
    ])

    static var defaultStorageValue: String {
        defaultValue.encoded()
    }

    var availableCards: [HomeScreenCardID] {
        HomeScreenCardID.allCases.filter { id in
            !cards.contains { $0.id == id }
        }
    }

    func encoded() -> String {
        guard let data = try? JSONEncoder().encode(self),
              let string = String(data: data, encoding: .utf8) else {
            return "{\"cards\":[]}"
        }

        return string
    }

    static func decoded(from rawValue: String) -> HomeScreenLayout {
        guard let data = rawValue.data(using: .utf8),
              let layout = try? JSONDecoder().decode(HomeScreenLayout.self, from: data) else {
            return defaultValue
        }

        return layout.normalized()
    }

    func normalized() -> HomeScreenLayout {
        var seenIDs: Set<HomeScreenCardID> = []
        let normalizedCards = cards.compactMap { card -> HomeScreenCardConfiguration? in
            guard !seenIDs.contains(card.id) else {
                return nil
            }

            seenIDs.insert(card.id)
            return HomeScreenCardConfiguration(
                id: card.id,
                size: card.id.supportsResizing ? card.size : .standard
            )
        }

        return HomeScreenLayout(cards: normalizedCards)
    }
}

struct HomeScreenCardConfiguration: Codable, Equatable, Identifiable {
    let id: HomeScreenCardID
    var size: HomeScreenCardSize
}

enum HomeScreenCardID: String, CaseIterable, Codable, Identifiable {
    case greeting
    case overview
    case quickActions
    case recentActivity
    case focusAreas

    var id: String { rawValue }

    var title: String {
        switch self {
        case .greeting:
            return "Greeting"
        case .overview:
            return "Daily overview"
        case .quickActions:
            return "Quick actions"
        case .recentActivity:
            return "Recent activity"
        case .focusAreas:
            return "Focus areas"
        }
    }

    var subtitle: String {
        switch self {
        case .greeting:
            return "Date, greeting, and latest log summary"
        case .overview:
            return "Progress ring and daily stats"
        case .quickActions:
            return "Prayer and logging shortcuts"
        case .recentActivity:
            return "Latest timeline entries"
        case .focusAreas:
            return "Your focus area list"
        }
    }

    var systemImage: String {
        switch self {
        case .greeting:
            return "sun.max.fill"
        case .overview:
            return "chart.line.uptrend.xyaxis"
        case .quickActions:
            return "bolt.fill"
        case .recentActivity:
            return "clock.arrow.circlepath"
        case .focusAreas:
            return "list.bullet.rectangle.fill"
        }
    }

    var supportsResizing: Bool {
        switch self {
        case .greeting, .overview, .quickActions, .recentActivity:
            return true
        case .focusAreas:
            return false
        }
    }
}

enum HomeScreenCardSize: String, CaseIterable, Codable, Identifiable {
    case minimal
    case compact
    case standard

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case Self.minimal.rawValue:
            self = .minimal
        case Self.compact.rawValue:
            self = .compact
        case Self.standard.rawValue, "expanded":
            self = .standard
        default:
            self = .standard
        }
    }

    var title: String {
        switch self {
        case .minimal:
            return "Minimal"
        case .compact:
            return "Compact"
        case .standard:
            return "Standard"
        }
    }
}
