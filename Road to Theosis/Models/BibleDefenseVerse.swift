import Foundation

struct BibleDefenseVerse: Codable, Identifiable {
    var id = UUID()
    let title: String
    let reference: String
    let translation: String
    let excerpt: String
    let application: String
    let symbol: String

    init(
        id: UUID = UUID(),
        title: String,
        reference: String,
        translation: String,
        excerpt: String,
        application: String,
        symbol: String
    ) {
        self.id = id
        self.title = title
        self.reference = reference
        self.translation = translation
        self.excerpt = excerpt
        self.application = application
        self.symbol = symbol
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        reference = try container.decodeIfPresent(String.self, forKey: .reference) ?? ""
        translation = try container.decode(String.self, forKey: .translation)
        excerpt = try container.decode(String.self, forKey: .excerpt)
        application = try container.decode(String.self, forKey: .application)
        symbol = try container.decode(String.self, forKey: .symbol)
    }

    static let placeholder = BibleDefenseVerse(
        title: "Stand Firm",
        reference: "James 4:7",
        translation: "NKJV",
        excerpt: "Resist the devil, and he will flee from you.",
        application: "Add your own defense verses for this focus area when you are ready.",
        symbol: "shield.lefthalf.filled"
    )

    static let defaultVerses: [BibleDefenseVerse] = [placeholder]
}
