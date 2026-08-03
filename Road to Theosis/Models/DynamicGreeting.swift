import Foundation

struct GreetingWeatherSnapshot: Equatable {
    let condition: GreetingWeatherCondition
    let temperatureCelsius: Double?
    let windSpeedKilometersPerHour: Double?

    var shortDescription: String {
        condition.shortDescription
    }
}

enum GreetingWeatherCondition: Equatable {
    case clear
    case partlyCloudy
    case cloudy
    case rain
    case snow
    case storm
    case fog
    case breezy
    case hot
    case cold
    case unknown

    var shortDescription: String {
        switch self {
        case .clear:
            return "clear"
        case .partlyCloudy:
            return "partly cloudy"
        case .cloudy:
            return "cloudy"
        case .rain:
            return "rainy"
        case .snow:
            return "snowy"
        case .storm:
            return "stormy"
        case .fog:
            return "foggy"
        case .breezy:
            return "breezy"
        case .hot:
            return "warm"
        case .cold:
            return "cold"
        case .unknown:
            return "steady"
        }
    }
}

struct DynamicGreetingContext: Equatable {
    let date: Date
    let recentEntries: [LogEntry]
    let weather: GreetingWeatherSnapshot?
    let calendar: Calendar

    init(
        date: Date,
        recentEntries: [LogEntry],
        weather: GreetingWeatherSnapshot?,
        calendar: Calendar = .current
    ) {
        self.date = date
        self.recentEntries = recentEntries
        self.weather = weather
        self.calendar = calendar
    }
}

struct DynamicGreeting: Equatable {
    let title: String
    let subtitle: String
    let compactTitle: String
    let compactSubtitle: String
    let minimalTitle: String
    let minimalSubtitle: String
    let symbolName: String
}

enum DynamicGreetingComposer {
    static func compose(context: DynamicGreetingContext) -> DynamicGreeting {
        let daypart = GreetingDaypart(date: context.date, calendar: context.calendar)
        let recentPattern = RecentLogPattern(entries: context.recentEntries, now: context.date, calendar: context.calendar)
        let weather = context.weather
        let symbolName = symbolName(for: daypart, weather: weather)

        return DynamicGreeting(
            title: daypart.title,
            subtitle: subtitle(daypart: daypart, weather: weather, recentPattern: recentPattern),
            compactTitle: daypart.compactTitle,
            compactSubtitle: compactSubtitle(daypart: daypart, weather: weather, recentPattern: recentPattern),
            minimalTitle: daypart.minimalTitle,
            minimalSubtitle: minimalSubtitle(daypart: daypart, weather: weather, recentPattern: recentPattern),
            symbolName: symbolName
        )
    }

    private static func symbolName(for daypart: GreetingDaypart, weather: GreetingWeatherSnapshot?) -> String {
        switch weather?.condition {
        case .rain:
            return "cloud.rain.fill"
        case .snow:
            return "cloud.snow.fill"
        case .storm:
            return "cloud.bolt.rain.fill"
        case .fog:
            return "cloud.fog.fill"
        case .breezy:
            return "wind"
        case .cloudy:
            return "cloud.fill"
        case .partlyCloudy:
            return daypart.prefersSunSymbol ? "cloud.sun.fill" : "cloud.moon.fill"
        case .clear, .hot:
            return daypart.prefersSunSymbol ? "sun.max.fill" : "moon.stars.fill"
        case .cold:
            return "thermometer.snowflake"
        case .unknown, .none:
            return daypart.prefersSunSymbol ? "sun.max.fill" : "moon.stars.fill"
        }
    }

    private static func subtitle(
        daypart: GreetingDaypart,
        weather: GreetingWeatherSnapshot?,
        recentPattern: RecentLogPattern
    ) -> String {
        let weatherLine = standardWeatherPhrase(daypart: daypart, weather: weather)
        let logLine = recentPattern.subtitlePhrase
        return "\(weatherLine) \(logLine) \(daypart.theosisFocus)"
    }

    private static func compactSubtitle(
        daypart: GreetingDaypart,
        weather: GreetingWeatherSnapshot?,
        recentPattern: RecentLogPattern
    ) -> String {
        let weatherLine = compactWeatherPhrase(daypart: daypart, weather: weather)
        return "\(weatherLine) \(recentPattern.compactPhrase)"
    }

    private static func minimalSubtitle(
        daypart: GreetingDaypart,
        weather: GreetingWeatherSnapshot?,
        recentPattern: RecentLogPattern
    ) -> String {
        "\(minimalWeatherPhrase(daypart: daypart, weather: weather)) \(recentPattern.minimalPhrase)"
    }

    private static func standardWeatherPhrase(daypart: GreetingDaypart, weather: GreetingWeatherSnapshot?) -> String {
        guard let weather else {
            return daypart.defaultWeatherPhrase
        }

        switch (daypart.kind, weather.condition) {
        case (.morning, .clear), (.morning, .hot):
            return "The morning is bright; receive it with prayer before the day starts pulling at you."
        case (.morning, .partlyCloudy), (.morning, .cloudy):
            return "This softer morning is still a gift; begin it calmly and keep your eyes on Christ."
        case (.morning, .rain):
            return "Rain is setting a slower morning rhythm; let it draw you into prayer and steady obedience."
        case (.morning, .breezy):
            return "A breezy morning can feel restless; anchor your first steps in prayer and attention."
        case (.afternoon, .clear), (.afternoon, .hot):
            return "The afternoon is bright; keep your progress humble and your next choice clean."
        case (.afternoon, .rain):
            return "Rain in the afternoon is a good cue to slow down, reset, and continue the road to theosis."
        case (.afternoon, .breezy):
            return "A moving afternoon calls for a steady heart; pause before reacting and choose the narrow path."
        case (.evening, .clear), (.evening, .partlyCloudy):
            return "The evening is opening gently; look back with gratitude and keep watch over your heart."
        case (.evening, .rain):
            return "Rain this evening makes room for reflection; bring the day honestly before God."
        case (.night, .clear), (.night, .partlyCloudy):
            return "The night is quiet; close the day with thanksgiving, confession, and peace."
        case (.night, .breezy):
            return "A breezy night can stir the mind; settle it with prayer before sleep."
        case (_, .storm):
            return "Stormy weather is a reminder to seek shelter in God before anything else."
        case (_, .snow):
            return "Snow invites quiet attention; move slowly and keep your soul ordered toward God."
        case (_, .fog):
            return "Fog makes the next step matter more than the whole road; take the faithful next step."
        case (_, .cold):
            return "The cold asks for discipline; let your warmth come from prayer and a clean direction."
        case (_, .cloudy):
            return "The sky is heavy, but the path is still clear: one faithful choice at a time."
        case (_, .unknown):
            return daypart.defaultWeatherPhrase
        default:
            return daypart.defaultWeatherPhrase
        }
    }

    private static func compactWeatherPhrase(daypart: GreetingDaypart, weather: GreetingWeatherSnapshot?) -> String {
        guard let weather else {
            return daypart.defaultCompactWeatherPhrase
        }

        switch (daypart.kind, weather.condition) {
        case (.morning, .clear), (.morning, .hot):
            return "Bright morning; begin with prayer before the day starts pulling at you."
        case (.morning, .partlyCloudy), (.morning, .cloudy):
            return "Soft morning; start steady and keep your eyes on Christ."
        case (.morning, .rain):
            return "Rain slows the morning; use the quieter rhythm for prayer."
        case (.morning, .breezy):
            return "Breezy morning; anchor your first step before the day moves fast."
        case (.afternoon, .clear), (.afternoon, .hot):
            return "Bright afternoon; keep your progress humble and the next choice clean."
        case (.afternoon, .rain):
            return "Rainy afternoon; slow down, reset, and continue the road to theosis."
        case (.afternoon, .breezy):
            return "Moving afternoon; keep a steady heart before reacting."
        case (.evening, .clear), (.evening, .partlyCloudy):
            return "Gentle evening; review the day with gratitude and watchfulness."
        case (.evening, .rain):
            return "Rainy evening; bring the day honestly before God."
        case (.night, .clear), (.night, .partlyCloudy):
            return "Quiet night; close the day with thanksgiving, confession, and peace."
        case (.night, .breezy):
            return "Breezy night; settle the mind with prayer before sleep."
        case (_, .storm):
            return "Stormy weather; seek shelter in God before anything else."
        case (_, .snow):
            return "Snow invites quiet attention; move slowly and keep your soul ordered."
        case (_, .fog):
            return "Fog narrows the road; take the faithful next step."
        case (_, .cold):
            return "Cold outside; let discipline and prayer keep your direction warm."
        case (_, .cloudy):
            return "Cloudy sky; the path is still clear one faithful choice at a time."
        case (_, .unknown):
            return daypart.defaultCompactWeatherPhrase
        default:
            return daypart.defaultCompactWeatherPhrase
        }
    }

    private static func minimalWeatherPhrase(daypart: GreetingDaypart, weather: GreetingWeatherSnapshot?) -> String {
        guard let weather else {
            return daypart.defaultMinimalWeatherPhrase
        }

        switch weather.condition {
        case .clear, .hot:
            return daypart.prefersSunSymbol ? "Bright day; receive it with prayer." : "Quiet night; close it with prayer."
        case .partlyCloudy:
            return daypart.prefersSunSymbol ? "Soft light; start steady." : "Quiet sky; stay watchful."
        case .cloudy:
            return "Cloudy sky; stay steady."
        case .rain:
            return "Rain slows things down."
        case .snow:
            return "Snow invites quiet attention."
        case .storm:
            return "Seek shelter in God."
        case .fog:
            return "Fog means one faithful next step."
        case .breezy:
            return "Breezy outside; stay anchored."
        case .cold:
            return "Cold asks for discipline."
        case .unknown:
            return daypart.defaultMinimalWeatherPhrase
        }
    }
}

private struct GreetingDaypart: Equatable {
    enum Kind: Equatable {
        case morning
        case afternoon
        case evening
        case night
    }

    let kind: Kind

    init(date: Date, calendar: Calendar) {
        let hour = calendar.component(.hour, from: date)

        switch hour {
        case 5..<12:
            kind = .morning
        case 12..<17:
            kind = .afternoon
        case 17..<22:
            kind = .evening
        default:
            kind = .night
        }
    }

    var title: String {
        switch kind {
        case .morning:
            return "Good morning"
        case .afternoon:
            return "Good afternoon"
        case .evening:
            return "Good evening"
        case .night:
            return "Good night"
        }
    }

    var compactTitle: String {
        title
    }

    var minimalTitle: String {
        switch kind {
        case .morning:
            return "Morning"
        case .afternoon:
            return "Afternoon"
        case .evening:
            return "Evening"
        case .night:
            return "Night"
        }
    }

    var prefersSunSymbol: Bool {
        switch kind {
        case .morning, .afternoon:
            return true
        case .evening, .night:
            return false
        }
    }

    var defaultWeatherPhrase: String {
        switch kind {
        case .morning:
            return "Begin this morning with prayer and a clear intention for the road to theosis."
        case .afternoon:
            return "Use this afternoon as a reset point and keep moving toward God with attention."
        case .evening:
            return "Let this evening become a quiet review of grace, resistance, and needed repentance."
        case .night:
            return "Bring the day to God, release what needs mercy, and rest with a watchful heart."
        }
    }

    var defaultCompactWeatherPhrase: String {
        switch kind {
        case .morning:
            return "Begin with prayer and clear intent before the day starts pulling at you."
        case .afternoon:
            return "Use this afternoon as a reset point and keep moving toward God."
        case .evening:
            return "Review the day with grace, honesty, and needed repentance."
        case .night:
            return "Bring the day to God, release what needs mercy, and rest."
        }
    }

    var defaultMinimalWeatherPhrase: String {
        switch kind {
        case .morning:
            return "Pray first and set your intention."
        case .afternoon:
            return "Reset now and choose the narrow path."
        case .evening:
            return "Review today with grace and honesty."
        case .night:
            return "Bring the day to God and rest clean."
        }
    }

    var theosisFocus: String {
        switch kind {
        case .morning:
            return "Put on the full armor of God and start with one faithful act."
        case .afternoon:
            return "The road is built by the next faithful choice, not by feelings alone."
        case .evening:
            return "Notice where grace helped you resist and where repentance should begin."
        case .night:
            return "End the day honestly so tomorrow can begin with a cleaner heart."
        }
    }
}

private struct RecentLogPattern: Equatable {
    private let entriesToday: [LogEntry]
    private let latestEntry: LogEntry?

    init(entries: [LogEntry], now: Date, calendar: Calendar) {
        let sortedEntries = entries.sorted { $0.occurredAt > $1.occurredAt }
        entriesToday = sortedEntries.filter { calendar.isDate($0.occurredAt, inSameDayAs: now) }
        latestEntry = sortedEntries.first
    }

    var subtitlePhrase: String {
        if entriesToday.isEmpty {
            return "No logs yet today, so make the first one intentional instead of accidental."
        }

        let victories = entriesToday.filter { $0.kind == .victory }.count
        let losses = entriesToday.filter { $0.kind == .loss }.count
        let prayers = entriesToday.filter { $0.kind == .prayer || $0.kind == .quickPrayer }.count
        let progressUpdates = entriesToday.filter { $0.kind == .progressUpdate || $0.kind == .sliderProgressUpdate }.count

        if losses > 0 {
            return "After \(losses) fall\(losses == 1 ? "" : "s") today, do not spiral; confess, stand up, and return to the path."
        }

        if victories > 0 {
            return "You have \(victories) resistance log\(victories == 1 ? "" : "s") today; receive that as grace and stay vigilant."
        }

        if prayers > 0 {
            return "Prayer is already present in today's rhythm; keep letting it shape your next decision."
        }

        if progressUpdates > 0 {
            return "You checked your progress today; now turn the number into a concrete act of obedience."
        }

        return latestEntryPhrase
    }

    var compactPhrase: String {
        if entriesToday.isEmpty {
            return "Make the first log intentional."
        }

        let victories = entriesToday.filter { $0.kind == .victory }.count
        let losses = entriesToday.filter { $0.kind == .loss }.count
        let prayers = entriesToday.filter { $0.kind == .prayer || $0.kind == .quickPrayer }.count

        if losses > 0 {
            return "Return after the fall."
        }

        if victories > 0 {
            return "Stay vigilant after resistance."
        }

        if prayers > 0 {
            return "Let prayer shape the next step."
        }

        return "Keep the next choice faithful."
    }

    var minimalPhrase: String {
        if entriesToday.isEmpty {
            return "Make the first log intentional."
        }

        let victories = entriesToday.filter { $0.kind == .victory }.count
        let losses = entriesToday.filter { $0.kind == .loss }.count
        let prayers = entriesToday.filter { $0.kind == .prayer || $0.kind == .quickPrayer }.count

        if losses > 0 {
            return "Confess, stand up, and return now."
        }

        if victories > 0 {
            return "Give thanks and stay watchful."
        }

        if prayers > 0 {
            return "Carry that prayer into action."
        }

        return "Turn the next choice into obedience."
    }

    private var latestEntryPhrase: String {
        guard let latestEntry else {
            return "The log is quiet right now; choose the next faithful step deliberately."
        }

        switch latestEntry.kind {
        case .prayer, .quickPrayer:
            return "Your latest log was prayer; let that conversation continue into action."
        case .victory:
            return "Your latest log was resistance; give thanks and keep watch."
        case .loss:
            return "Your latest log was a fall; mercy is not permission to stay down."
        case .progressUpdate, .sliderProgressUpdate:
            return "Your latest log checked progress; let it guide one practical act."
        case .note:
            return "Your latest note matters; turn reflection into one faithful move."
        }
    }
}
