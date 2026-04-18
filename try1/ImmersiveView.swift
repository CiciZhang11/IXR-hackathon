import SwiftUI
import RealityKit
import simd
import UIKit
struct ImmersiveView: View {
    // We are keeping the state here for this example so it works instantly.
    // In a full app, these would live in your AppModel!
    @State private var arrowOrigin: SIMD3<Float> = SIMD3(x: 0, y: 1.2, z: -0.5)
    @State private var targetPosition: SIMD3<Float> = SIMD3(x: 0, y: 1.2, z: -2.0)
    
    // What percentage of the distance should the arrow cover? (0.8 = 80%)
    @State private var arrowPercentage: Float = 0.8
    var body: some View {
        RealityView { content in
            // 1. Create the base container. This is what we will rotate.
            let arrowContainer = Entity()
            arrowContainer.name = "ArrowContainer"
            
            // 2. Make it Pretty: A glowing, metallic cyan material
            var shinyMaterial = PhysicallyBasedMaterial()
            shinyMaterial.baseColor.tint = .cyan
            shinyMaterial.metallic = 1.0
            shinyMaterial.roughness = 0.2
            shinyMaterial.emissiveColor.color = .cyan
            shinyMaterial.emissiveIntensity = 1.5
            
            // 3. Build the Shaft (Default length is 1 meter)
            let shaftMesh = MeshResource.generateCylinder(height: 1.0, radius: 0.015)
            let shaft = ModelEntity(mesh: shaftMesh, materials: [shinyMaterial])
            shaft.name = "Shaft"
            // Rotate the shaft so it points forward along the Z-axis
            shaft.transform.rotation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            
            // 4. Build the Tip
            let tipMesh = MeshResource.generateCone(height: 0.15, radius: 0.06)
            let tip = ModelEntity(mesh: tipMesh, materials: [shinyMaterial])
            tip.name = "Tip"
            tip.transform.rotation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
            
            // Assemble and add to scene
            arrowContainer.addChild(shaft)
            arrowContainer.addChild(tip)
            content.add(arrowContainer)
            
        } update: { content in
            // --- THIS RUNS EVERY TIME DATA CHANGES ---
            
            // Find our arrow parts
            guard let arrowContainer = content.entities.first(where: { $0.name == "ArrowContainer" }),
                  let shaft = arrowContainer.findEntity(named: "Shaft"),
                  let tip = arrowContainer.findEntity(named: "Tip") else { return }
            
            // 1. Point the Arrow!
            // look(at:) automatically swivels the container to face the target.
            arrowContainer.look(at: targetPosition, from: arrowOrigin, relativeTo: nil)
            
            // 2. Calculate the total distance in meters
            let totalDistance = distance(arrowOrigin, targetPosition)
            
            // 3. Calculate how long the physical arrow should be based on our percentage
            let physicalLength = totalDistance * arrowPercentage
            
            // 4. The Anti-Squash Magic:
            // Scale the shaft's length (its local Y axis) to match the new length
            shaft.scale.y = physicalLength
            
            // Shift the shaft forward so its base stays at the origin
            shaft.position.z = -(physicalLength / 2.0)
            
            // Slide the un-stretched tip to the very end of the shaft
            tip.position.z = -physicalLength
        }
        .onAppear {
            // A fun little loop to make the target move in a circle
            // so you can see the arrow dynamically working!
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                let time = Date().timeIntervalSince1970
                // Target orbits back and forth and moves in and out
                targetPosition.x = Float(sin(time * 2)) * 1.5
                targetPosition.y = 1.2 + Float(cos(time)) * 0.5
                targetPosition.z = -2.0 + Float(sin(time * 1.5)) * 1.0
            }
        }
    }
}
#Preview(immersionStyle: .full) {
    ImmersiveView()
}


