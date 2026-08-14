import Foundation

struct GreetingWeatherThresholds {
    static let defaultWarmThresholdCelsius = 24.0
    static let defaultColdThresholdCelsius = 6.0
    static let defaultBreezyThresholdKilometersPerHour = 24.0

    let warmThresholdCelsius: Double
    let coldThresholdCelsius: Double
    let breezyThresholdKilometersPerHour: Double
}

struct GreetingWeather {
    let temperatureCelsius: Double
    let windSpeedKilometersPerHour: Double
}

struct GreetingWeatherService {
    func currentWeather(thresholds: GreetingWeatherThresholds) async -> GreetingWeather? {
        nil
    }
}
