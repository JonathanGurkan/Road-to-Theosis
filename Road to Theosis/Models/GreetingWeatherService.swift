import CoreLocation
import Foundation

struct GreetingWeatherSnapshot: Equatable, Sendable {
    let condition: GreetingWeatherCondition
    let temperatureCelsius: Double?
    let windSpeedKilometersPerHour: Double?
}

enum GreetingWeatherCondition: String, Equatable, Sendable {
    case clear
    case partlyCloudy
    case cloudy
    case fog
    case rain
    case snow
    case storm
    case breezy
    case hot
    case cold
    case unknown
}

@MainActor
final class GreetingWeatherService: NSObject, CLLocationManagerDelegate {
    private enum WeatherError: Error {
        case locationUnavailable
        case locationAccessDenied
        case weatherUnavailable
    }

    private struct OpenMeteoResponse: Decodable {
        let current: CurrentWeather
    }

    private struct CurrentWeather: Decodable {
        let temperatureCelsius: Double?
        let weatherCode: Int
        let windSpeedKilometersPerHour: Double?

        enum CodingKeys: String, CodingKey {
            case temperatureCelsius = "temperature_2m"
            case weatherCode = "weather_code"
            case windSpeedKilometersPerHour = "wind_speed_10m"
        }
    }

    private let locationManager = CLLocationManager()
    private var authorizationContinuation: CheckedContinuation<Void, Never>?
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }

    func currentWeather(thresholds: GreetingWeatherThresholds) async -> GreetingWeatherSnapshot? {
        do {
            let location = try await currentLocation()
            return try await fetchWeather(for: location, thresholds: thresholds)
        } catch {
            return nil
        }
    }

    private func currentLocation() async throws -> CLLocation {
        guard Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil else {
            throw WeatherError.locationUnavailable
        }

        guard CLLocationManager.locationServicesEnabled() else {
            throw WeatherError.locationUnavailable
        }

        try await requestAuthorizationIfNeeded()

        guard locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways else {
            throw WeatherError.locationAccessDenied
        }

        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()
        }
    }

    private func requestAuthorizationIfNeeded() async throws {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            await withCheckedContinuation { continuation in
                authorizationContinuation = continuation
                locationManager.requestWhenInUseAuthorization()
            }
        case .restricted, .denied:
            throw WeatherError.locationAccessDenied
        case .authorizedAlways, .authorizedWhenInUse:
            break
        @unknown default:
            throw WeatherError.locationUnavailable
        }
    }

    private func fetchWeather(for location: CLLocation, thresholds: GreetingWeatherThresholds) async throws -> GreetingWeatherSnapshot {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(location.coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,wind_speed_10m"),
            URLQueryItem(name: "wind_speed_unit", value: "kmh")
        ]

        guard let url = components?.url else {
            throw WeatherError.weatherUnavailable
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw WeatherError.weatherUnavailable
        }

        let decodedResponse = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        return GreetingWeatherSnapshot(
            condition: weatherCondition(from: decodedResponse.current, thresholds: thresholds),
            temperatureCelsius: decodedResponse.current.temperatureCelsius,
            windSpeedKilometersPerHour: decodedResponse.current.windSpeedKilometersPerHour
        )
    }

    private func weatherCondition(from weather: CurrentWeather, thresholds: GreetingWeatherThresholds) -> GreetingWeatherCondition {
        if let windSpeed = weather.windSpeedKilometersPerHour, windSpeed >= thresholds.breezyThresholdKilometersPerHour {
            return .breezy
        }

        if let temperature = weather.temperatureCelsius {
            if temperature >= thresholds.warmThresholdCelsius {
                return .hot
            }

            if temperature <= thresholds.coldThresholdCelsius {
                return .cold
            }
        }

        switch weather.weatherCode {
        case 0:
            return .clear
        case 1, 2:
            return .partlyCloudy
        case 3:
            return .cloudy
        case 45, 48:
            return .fog
        case 51...67, 80...82:
            return .rain
        case 71...77, 85...86:
            return .snow
        case 95...99:
            return .storm
        default:
            return .unknown
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationContinuation?.resume()
        authorizationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            locationContinuation?.resume(throwing: WeatherError.locationUnavailable)
            locationContinuation = nil
            return
        }

        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }
}
