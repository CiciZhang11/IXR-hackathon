import SwiftUI
import RealityKit
import simd
import AVFoundation

struct ImmersiveView: View {
    @Environment(AppModel.self) var appModel
    
    @State private var arrowOrigin: SIMD3<Float> = SIMD3(x: 0, y: 0.5, z: -0.5)
    @State private var targetPosition: SIMD3<Float> = SIMD3(x: 0, y: 0.5, z: -2.0)
    
    @State private var arrowPercentage: Float = 0.8
    @State private var audioPlayer: AVAudioPlayer?
    @State private var geigerTimer: Timer?
    @State private var currentDistance: Float = 2.0
    
    // NEW: We need to track exact time for the sine wave animation
    @State private var currentTime: TimeInterval = 0

    var body: some View {
        RealityView { content in
            let arrowContainer = Entity()
            arrowContainer.name = "ArrowContainer"
            
            var shinyMaterial = PhysicallyBasedMaterial()
            shinyMaterial.baseColor.tint = .white // Changed to white to act as a better mirror
            shinyMaterial.metallic = 1.0
            shinyMaterial.roughness = 0.2
            // We set the initial glow to cyan
            shinyMaterial.emissiveColor.color = .cyan
            shinyMaterial.emissiveIntensity = 0.5
            
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
                  let shaft = arrowContainer.findEntity(named: "Shaft") as? ModelEntity,
                  let tip = arrowContainer.findEntity(named: "Tip") as? ModelEntity else { return }
            
            // 1. Point and Scale the Arrow
            arrowContainer.look(at: targetPosition, from: arrowOrigin, relativeTo: nil)
            let totalDistance = distance(arrowOrigin, targetPosition)
            let physicalLength = totalDistance * arrowPercentage
            
            shaft.scale.y = physicalLength
            shaft.position.z = -(physicalLength / 2.0)
            tip.position.z = -physicalLength
            
            // 2. THE BREATHING MATERIAL MATH
            // Faster heartbeat when closer (signal is higher)
            let breathSpeed = 2.0 + (Double(appModel.signalPercentage) * 0.1)
            // A sine wave that smoothly goes from 0.0 to 1.0
            let pulse = Float(sin(currentTime * breathSpeed) + 1.0) / 2.0
            // Base brightness increases as you get closer
            let baseGlow = Float(appModel.signalPercentage) / 100.0 * 2.0
            let totalIntensity = baseGlow + pulse
            
            // 3. Apply the new intensity to the models
            if var modelComp = shaft.components[ModelComponent.self],
               var mat = modelComp.materials.first as? PhysicallyBasedMaterial {
                mat.emissiveIntensity = totalIntensity
                modelComp.materials = [mat]
                shaft.components.set(modelComp)
                tip.components.set(modelComp) // Apply same material to tip
            }
        }
        .onAppear {
                    triggerGeigerCounter()
                    
                    Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                        // NEW: Tell Swift to execute this on the Main UI Thread
                        Task { @MainActor in
                            let time = Date().timeIntervalSince1970
                            currentTime = time // Save time for the breathing math
                            
                            targetPosition.x = Float(sin(time * 2)) * 1.5
                            targetPosition.y = 0.5 + Float(cos(time)) * 0.5
                            targetPosition.z = -2.0 + Float(sin(time * 1.5)) * 1.0
                            
                            currentDistance = distance(arrowOrigin, targetPosition)
                            
                            let clampedDistance = max(0.2, min(currentDistance, 3.0))
                            let percentage = (3.0 - clampedDistance) / 2.8 * 100
                            
                            // The compiler is now happy to mutate this!
                            appModel.signalPercentage = Int(percentage)
                        }
                    }
                }
        .onDisappear {
            geigerTimer?.invalidate()
        }
    }
    
    // MARK: - Geiger Counter Logic (Using System Sounds)
    
    func triggerGeigerCounter() {
        geigerTimer?.invalidate()
        let clampedDistance = max(0.2, min(currentDistance, 3.0))
        let interval = Double(clampedDistance) * 0.5
        let pitchRate = 2.5 - (Float(clampedDistance) * 0.6)
        
        playSound(rate: pitchRate)
        
        geigerTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
                    // NEW: Ensure the next call also happens on the Main Thread
                    Task { @MainActor in
                        triggerGeigerCounter()
                    }
                }
    }
    
    func playSound(rate: Float) {
        let systemSoundPath = "/System/Library/Audio/UISounds/\(appModel.selectedSound).caf"
        let url = URL(fileURLWithPath: systemSoundPath)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.enableRate = true
            audioPlayer?.rate = rate
            audioPlayer?.play()
        } catch {
            print("Could not play system sound: \(error.localizedDescription)")
        }
    }
}
#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}
