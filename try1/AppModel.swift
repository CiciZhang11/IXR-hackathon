import SwiftUI
import Observation

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
    
    // NEW: Built-in Apple System Sounds
    // These correspond exactly to the hidden .caf files on Apple devices
    var selectedSound = "Tink"
    let availableSounds = ["Tink", "Tock", "Pop", "Modern_beep"]
    
    var signalPercentage: Int = 0
}
