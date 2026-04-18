import CoreLocation
import Foundation

final class CoreLocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    var onLocationUpdated: ((CLLocation) -> Void)?
    var onCourseUpdated: ((Double) -> Void)?
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
    }

    func stop() {
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        onLocationUpdated?(location)

        if location.course >= 0 {
            onCourseUpdated?(location.course)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onError?(error.localizedDescription)
    }
}
