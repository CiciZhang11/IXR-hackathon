//
//  AppModel.swift
//  try1
//
//  Created by iguest on 4/18/26.
//

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

    // MARK: - Firebase-backed location state

    private let locationService = FirebaseLocationService()

    /// Latest parsed location from Firebase (nil until first valid update).
    var remoteLocation: DeviceLocation?

    /// Human-readable stream status for basic diagnostics/UI.
    var locationStreamStatus: String = "idle"

    /// Latest listener/parsing error text (nil when healthy).
    var locationErrorMessage: String?

    /// Local receipt time for staleness checks / "last updated" labels.
    var lastLocationUpdateAt: Date?

    /// Starts streaming location updates from Firebase.
    func startLocationListening() {
        locationStreamStatus = "connecting"
        locationErrorMessage = nil

        locationService.onUpdate = { [weak self] location in
            guard let self else { return }
            // We are @MainActor; ensure state mutations land on the main actor.
            Task { @MainActor in
                self.remoteLocation = location
                self.lastLocationUpdateAt = Date()
                self.locationErrorMessage = nil
                self.locationStreamStatus = "listening"
            }
        }

        locationService.onError = { [weak self] message in
            guard let self else { return }
            Task { @MainActor in
                self.locationErrorMessage = message
                self.locationStreamStatus = "error"
            }
        }

        locationService.startListening()
    }

    /// Stops streaming updates and marks stream idle.
    func stopLocationListening() {
        locationService.stopListening()
        locationStreamStatus = "idle"
    }

    deinit {
        // Extra safety: detach listener if the model is ever released.
        locationService.stopListening()
    }
}
