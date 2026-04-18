import CoreLocation
import SwiftUI

@MainActor
@Observable
final class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"

    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }

    var immersiveSpaceState: ImmersiveSpaceState = .closed

    private let firebaseService = FirebaseLocationService()
    private let coreLocationService = CoreLocationService()

    var remoteLocation: DeviceLocation?
    var localLocation: CLLocation?
    var localCourseDegrees: Double?

    var targetDistanceMeters: Double?
    var targetRelativeBearingDegrees: Double?

    var locationStreamStatus: String = "idle"
    var locationErrorMessage: String?
    var lastLocationUpdateAt: Date?

    private var isListening = false

    init() {
        wireFirebase()
        wireCoreLocation()
    }

    func startLocationListening() {
        guard !isListening else { return }
        isListening = true
        locationStreamStatus = "connecting"
        locationErrorMessage = nil

        coreLocationService.start()
        firebaseService.startListening()
    }

    func stopLocationListening() {
        guard isListening else { return }
        isListening = false
        coreLocationService.stop()
        firebaseService.stopListening()
        locationStreamStatus = "idle"
    }

    deinit {
        coreLocationService.stop()
        firebaseService.stopListening()
    }

    private func wireFirebase() {
        firebaseService.onUpdate = { [weak self] location in
            guard let self else { return }
            Task { @MainActor in
                self.remoteLocation = location
                self.lastLocationUpdateAt = Date()
                self.locationErrorMessage = nil
                self.locationStreamStatus = "listening"
                self.recomputeTargetVector()
            }
        }

        firebaseService.onError = { [weak self] message in
            guard let self else { return }
            Task { @MainActor in
                self.locationErrorMessage = "Firebase: \(message)"
                self.locationStreamStatus = "error"
            }
        }
    }

    private func wireCoreLocation() {
        coreLocationService.onLocationUpdated = { [weak self] location in
            guard let self else { return }
            Task { @MainActor in
                self.localLocation = location
                self.locationStreamStatus = self.locationStreamStatus == "idle" ? "connecting" : self.locationStreamStatus
                self.recomputeTargetVector()
            }
        }

        coreLocationService.onCourseUpdated = { [weak self] courseDegrees in
            guard let self else { return }
            Task { @MainActor in
                self.localCourseDegrees = courseDegrees
                self.recomputeTargetVector()
            }
        }

        coreLocationService.onError = { [weak self] message in
            guard let self else { return }
            Task { @MainActor in
                self.locationErrorMessage = "CoreLocation: \(message)"
                self.locationStreamStatus = "error"
            }
        }
    }

    private func recomputeTargetVector() {
        guard let local = localLocation, let remote = remoteLocation else {
            targetDistanceMeters = nil
            targetRelativeBearingDegrees = nil
            return
        }

        let remoteLocation = CLLocation(latitude: remote.lat, longitude: remote.lon)
        targetDistanceMeters = local.distance(from: remoteLocation)

        let absoluteBearing = Self.initialBearingDegrees(from: local.coordinate, to: remoteLocation.coordinate)
        if let course = localCourseDegrees {
            targetRelativeBearingDegrees = Self.normalizeSignedDegrees(absoluteBearing - course)
        } else {
            targetRelativeBearingDegrees = absoluteBearing
        }
    }

    private static func initialBearingDegrees(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180.0
        let lon1 = from.longitude * .pi / 180.0
        let lat2 = to.latitude * .pi / 180.0
        let lon2 = to.longitude * .pi / 180.0

        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        return normalizeSignedDegrees(atan2(y, x) * 180.0 / .pi)
    }

    private static func normalizeSignedDegrees(_ degrees: Double) -> Double {
        var value = degrees.truncatingRemainder(dividingBy: 360.0)
        if value > 180.0 { value -= 360.0 }
        if value < -180.0 { value += 360.0 }
        return value
    }
}
