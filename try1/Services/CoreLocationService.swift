import CoreLocation
import Foundation

final class CoreLocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    var onLocationUpdated: ((CLLocation) -> Void)?
    var onHeadingUpdated: ((Double) -> Void)?
    var onError: ((String) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 1.0
    }

    func start() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        // visionOS does not reliably expose heading APIs; use course from location updates instead.
    }

    func stop() {
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        onLocationUpdated?(location)

        // Use movement direction when available (degrees from true north).
        // course is < 0 when invalid.
        if location.course >= 0 {
            onHeadingUpdated?(location.course)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onError?(error.localizedDescription)
    }
}
