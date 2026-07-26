import SwiftUI

enum AppBackgroundTheme: String, CaseIterable, Identifiable {
    case blood
    case midnight
    case cedar
    case ember
    case violet

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .blood: return "Blood"
        case .midnight: return "Midnight"
        case .cedar: return "Cedar"
        case .ember: return "Ember"
        case .violet: return "Violet"
        }
    }

    var description: String {
        switch self {
        case .blood: return "A dark red background that reflects the blood Christ shed for our sins."
        case .midnight: return "Cool dark blues with a calm teal glow."
        case .cedar: return "Soft forest tones with a grounded, warm feel."
        case .ember: return "A richer amber background with a focused glow."
        case .violet: return "Deep violet shadows with a reflective mood."
        }
    }

    var colors: [Color] {
        switch self {
        case .blood:
            return [
                Color(red: 0.11, green: 0.02, blue: 0.01),
                Color(red: 0.27, green: 0.05, blue: 0.02),
                Color(red: 0.43, green: 0.09, blue: 0.05)
            ]
        case .midnight:
            return [
                Color(red: 0.05, green: 0.10, blue: 0.14),
                Color(red: 0.08, green: 0.16, blue: 0.18),
                Color(red: 0.14, green: 0.20, blue: 0.24)
            ]
        case .cedar:
            return [
                Color(red: 0.08, green: 0.12, blue: 0.10),
                Color(red: 0.12, green: 0.18, blue: 0.13),
                Color(red: 0.17, green: 0.23, blue: 0.16)
            ]
        case .ember:
            return [
                Color(red: 0.16, green: 0.08, blue: 0.08),
                Color(red: 0.24, green: 0.12, blue: 0.09),
                Color(red: 0.30, green: 0.18, blue: 0.10)
            ]
        case .violet:
            return [
                Color(red: 0.10, green: 0.08, blue: 0.17),
                Color(red: 0.16, green: 0.11, blue: 0.25),
                Color(red: 0.22, green: 0.15, blue: 0.31)
            ]
        }
    }

    var lightColors: [Color] {
        switch self {
        case .blood:
            return [
                Color(red: 0.98, green: 0.91, blue: 0.91),
                Color(red: 0.95, green: 0.84, blue: 0.83),
                Color(red: 0.88, green: 0.73, blue: 0.71)
            ]
        case .midnight:
            return [
                Color(red: 0.90, green: 0.94, blue: 0.98),
                Color(red: 0.81, green: 0.88, blue: 0.95),
                Color(red: 0.70, green: 0.82, blue: 0.92)
            ]
        case .cedar:
            return [
                Color(red: 0.92, green: 0.96, blue: 0.91),
                Color(red: 0.85, green: 0.92, blue: 0.84),
                Color(red: 0.76, green: 0.86, blue: 0.77)
            ]
        case .ember:
            return [
                Color(red: 0.99, green: 0.94, blue: 0.88),
                Color(red: 0.96, green: 0.87, blue: 0.74),
                Color(red: 0.90, green: 0.77, blue: 0.60)
            ]
        case .violet:
            return [
                Color(red: 0.95, green: 0.92, blue: 0.98),
                Color(red: 0.88, green: 0.84, blue: 0.96),
                Color(red: 0.79, green: 0.74, blue: 0.92)
            ]
        }
    }

    var glowColor: Color {
        switch self {
        case .blood: return .red
        case .midnight: return .cyan
        case .cedar: return .green
        case .ember: return .orange
        case .violet: return .purple
        }
    }
}
