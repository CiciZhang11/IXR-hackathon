//
//  AppModel.swift
//  try1
//
//  Created by iguest on 4/18/26.
//

import CoreLocation
import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed

    // MARK: - Services

    private let locationService = FirebaseLocationService()
    private let coreLocationService = CoreLocationService()

    // MARK: - Raw location state

    /// Latest parsed remote phone location from Firebase.
    var remoteLocation: DeviceLocation?

    /// Latest local Vision Pro location from CoreLocation.
    var localLocation: CLLocation?

    /// Latest local heading in degrees (true heading when available).
    var localHeadingDegrees: Double?

    // MARK: - Derived arrow state

    /// Distance from Vision Pro to phone in meters.
    var targetDistanceMeters: Double?

    /// Relative bearing for arrow UI: 0 = straight ahead, +right / -left.
    var targetRelativeBearingDegrees: Double?

    /// Human-readable stream status for diagnostics.
    var locationStreamStatus: String = "idle"

    /// Latest listener/parsing error text (nil when healthy).
    var locationErrorMessage: String?

    /// Local receipt time for staleness checks / "last updated" labels.
    var lastLocationUpdateAt: Date?

    private var isPipelineStarted = false

    init() {
        wireFirebase()
        wireCoreLocation()
    }

    /// Starts both Firebase and CoreLocation pipelines.
    func startLocationListening() {
        guard !isPipelineStarted else { return }
        isPipelineStarted = true

        locationStreamStatus = "connecting"
        locationErrorMessage = nil

        coreLocationService.start()
        locationService.startListening()
    }

    /// Stops all listeners and marks stream idle.
    func stopLocationListening() {
        guard isPipelineStarted else { return }
        isPipelineStarted = false

        locationService.stopListening()
        coreLocationService.stop()

        locationStreamStatus = "idle"
    }

    deinit {
        locationService.stopListening()
        coreLocationService.stop()
    }

    // MARK: - Wiring

    private func wireFirebase() {
        locationService.onUpdate = { [weak self] location in
            guard let self else { return }
            Task { @MainActor in
                self.remoteLocation = location
                self.lastLocationUpdateAt = Date()
                self.locationErrorMessage = nil
                self.locationStreamStatus = "listening"
                self.recomputeTargetVector()
            }
        }

        locationService.onError = { [weak self] message in
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
                self.recomputeTargetVector()
            }
        }

        coreLocationService.onHeadingUpdated = { [weak self] headingDegrees in
            guard let self else { return }
            Task { @MainActor in
                self.localHeadingDegrees = headingDegrees
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

    // MARK: - Distance/Bearing math

    private func recomputeTargetVector() {
        guard let local = localLocation, let remote = remoteLocation else {
            targetDistanceMeters = nil
            targetRelativeBearingDegrees = nil
            return
        }

        let remoteCL = CLLocation(latitude: remote.lat, longitude: remote.lon)
        targetDistanceMeters = local.distance(from: remoteCL)

        let absoluteBearing = Self.initialBearingDegrees(
            from: local.coordinate,
            to: remoteCL.coordinate
        )

        if let heading = localHeadingDegrees {
            targetRelativeBearingDegrees = Self.normalizeSignedDegrees(absoluteBearing - heading)
        } else {
            // Fallback if heading is unavailable yet.
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
        let radians = atan2(y, x)
        let deg = radians * 180.0 / .pi
        return normalizeSignedDegrees(deg)
    }

    private static func normalizeSignedDegrees(_ value: Double) -> Double {
        var v = value.truncatingRemainder(dividingBy: 360.0)
        if v > 180.0 { v -= 360.0 }
        if v < -180.0 { v += 360.0 }
        return v
    }
}
