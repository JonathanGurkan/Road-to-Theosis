import Foundation

struct GreetingWeatherThresholds: Equatable, Sendable {
    static let defaultWarmThresholdCelsius = 29.0
    static let defaultColdThresholdCelsius = 3.0
    static let defaultBreezyThresholdKilometersPerHour = 28.0

    static let `default` = GreetingWeatherThresholds()

    let warmThresholdCelsius: Double
    let coldThresholdCelsius: Double
    let breezyThresholdKilometersPerHour: Double

    init(
        warmThresholdCelsius: Double = Self.defaultWarmThresholdCelsius,
        coldThresholdCelsius: Double = Self.defaultColdThresholdCelsius,
        breezyThresholdKilometersPerHour: Double = Self.defaultBreezyThresholdKilometersPerHour
    ) {
        self.warmThresholdCelsius = warmThresholdCelsius
        self.coldThresholdCelsius = coldThresholdCelsius
        self.breezyThresholdKilometersPerHour = breezyThresholdKilometersPerHour
    }
}
