import SwiftUI
import RealityKit
import simd
import UIKit
import AVFoundation // NEW: Required for pitch-shifting audio

struct ImmersiveView: View {
    @Environment(AppModel.self) var appModel
    
    @State private var arrowOrigin: SIMD3<Float> = SIMD3(x: 0, y: 1.2, z: -0.5)
    @State private var targetPosition: SIMD3<Float> = SIMD3(x: 0, y: 1.2, z: -2.0)
    
    @State private var arrowPercentage: Float = 0.8
    
    // NEW: Geiger Counter State
    @State private var audioPlayer: AVAudioPlayer?
    @State private var geigerTimer: Timer?
    @State private var currentDistance: Float = 2.0

    var body: some View {
        RealityView { content in
            let arrowContainer = Entity()
            arrowContainer.name = "ArrowContainer"
            
            var shinyMaterial = PhysicallyBasedMaterial()
            shinyMaterial.baseColor.tint = .cyan
            shinyMaterial.metallic = 1.0
            shinyMaterial.roughness = 0.2
            shinyMaterial.emissiveColor.color = .cyan
            shinyMaterial.emissiveIntensity = 1.5
            
            let shaftMesh = MeshResource.generateCylinder(height: 1.0, radius: 0.015)
            let shaft = ModelEntity(mesh: shaftMesh, materials: [shinyMaterial])
            shaft.name = "Shaft"
            shaft.transform.rotation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            
            let tipMesh = MeshResource.generateCone(height: 0.15, radius: 0.06)
            let tip = ModelEntity(mesh: tipMesh, materials: [shinyMaterial])
            tip.name = "Tip"
            tip.transform.rotation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
            
            arrowContainer.addChild(shaft)
            arrowContainer.addChild(tip)
            content.add(arrowContainer)
            
        } update: { content in
            guard let arrowContainer = content.entities.first(where: { $0.name == "ArrowContainer" }),
                  let shaft = arrowContainer.findEntity(named: "Shaft"),
                  let tip = arrowContainer.findEntity(named: "Tip") else { return }
            
            arrowContainer.look(at: targetPosition, from: arrowOrigin, relativeTo: nil)
            let totalDistance = distance(arrowOrigin, targetPosition)
            let physicalLength = totalDistance * arrowPercentage
            
            shaft.scale.y = physicalLength
            shaft.position.z = -(physicalLength / 2.0)
            tip.position.z = -physicalLength
            
        }
        .onAppear {
            // Start the Geiger counter audio loop
            triggerGeigerCounter()
            
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                let time = Date().timeIntervalSince1970
                targetPosition.x = Float(sin(time * 2)) * 1.5
                targetPosition.y = 1.2 + Float(cos(time)) * 0.5
                targetPosition.z = -2.0 + Float(sin(time * 1.5)) * 1.0
                
                // Update the distance so the Geiger counter knows how fast to beep
                currentDistance = distance(arrowOrigin, targetPosition)
            }
        }
        .onDisappear {
            // Stop the beeping if the user closes the 3D space!
            geigerTimer?.invalidate()
        }
    }
    
    // MARK: - Geiger Counter Logic
    
    func triggerGeigerCounter() {
        geigerTimer?.invalidate() // Clear the old timer
        
        // 1. Clamp the distance so the math doesn't break (between 0.2m and 3.0m)
        let clampedDistance = max(0.2, min(currentDistance, 3.0))
        
        // 2. Calculate Speed: Closer = Faster interval
        // 3.0 meters away = 1.5 seconds between beeps. 0.2 meters away = 0.1 seconds.
        let interval = Double(clampedDistance) * 0.5
        
        // 3. Calculate Pitch: Closer = Higher Pitch
        // Rate of 0.5 is a deep thump. Rate of 2.0 is a high ping.
        let pitchRate = 2.5 - (Float(clampedDistance) * 0.6)
        
        // 4. Play the sound!
        playSound(rate: pitchRate)
        
        // 5. Schedule the next beep based on our new speed interval
        geigerTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            triggerGeigerCounter()
        }
    }
    
    func playSound(rate: Float) {
            // Point directly to Apple's internal system sounds folder
            let systemSoundPath = "/System/Library/Audio/UISounds/\(appModel.selectedSound).caf"
            let url = URL(fileURLWithPath: systemSoundPath)
            
            do {
                // Load the system sound into our player
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                
                // Apply the Geiger counter pitch shifting!
                audioPlayer?.enableRate = true
                audioPlayer?.rate = rate
                audioPlayer?.play()
            } catch {
                print("Could not play system sound. It may not exist on this OS version: \(error.localizedDescription)")
            }
        }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}
