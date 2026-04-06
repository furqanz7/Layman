import SwiftUI
import CoreLocation

@MainActor
final class ThemeManager: NSObject, ObservableObject {
    @Published var isNight: Bool = false
    @Published var colorScheme: ColorScheme = .light

    private let locationManager = CLLocationManager()
    private var timer: Timer?
    private var lastLocation: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.distanceFilter = 10_000
        requestAuthorization()
    }

    func requestAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            applyDefaultFallback()
        @unknown default:
            applyDefaultFallback()
        }
    }

    private func applyDefaultFallback() {
        updateNight(isNight: false)
    }

    private func updateNight(isNight: Bool) {
        self.isNight = isNight
        self.colorScheme = isNight ? .dark : .light
    }

    private func scheduleReevaluation(at date: Date) {
        timer?.invalidate()
        timer = Timer(fireAt: date, interval: 0, target: self, selector: #selector(handleTimer), userInfo: nil, repeats: false)
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }

    @objc private func handleTimer() {
        guard let location = lastLocation else { return }
        computeAndApplyForToday(location: location)
    }

    private func computeAndApplyForToday(location: CLLocation) {
        let now = Date()
        let solar = SolarCalculator(date: now, coordinate: location.coordinate)
        guard let sunrise = solar.sunrise, let sunset = solar.sunset else {
            applyDefaultFallback()
            return
        }

        let nightNow = (now < sunrise) || (now >= sunset)
        updateNight(isNight: nightNow)

        // Determine next reevaluation boundary
        let nextBoundary: Date
        if now < sunrise {
            nextBoundary = sunrise
        } else if now < sunset {
            nextBoundary = sunset
        } else {
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86400)
            let solarTomorrow = SolarCalculator(date: tomorrow, coordinate: location.coordinate)
            nextBoundary = solarTomorrow.sunrise ?? Calendar.current.startOfDay(for: tomorrow)
        }
        scheduleReevaluation(at: nextBoundary)
    }
}

extension ThemeManager: @MainActor CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        requestAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        computeAndApplyForToday(location: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        applyDefaultFallback()
    }
}
