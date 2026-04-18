//
//  ImmersiveView.swift
//  try1
//
//  Created by iguest on 4/18/26.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {

    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)
                let sphereMesh = MeshResource.generateSphere(radius: 0.5)
                            let sphereMaterial = SimpleMaterial(color: .red, isMetallic: true) // Fixed: 'true' instead of 'Bool'
                            let sphereModel = ModelEntity(mesh: sphereMesh, materials: [sphereMaterial])
                            
                            // 3. Position the sphere so it isn't inside your head
                            // x: 0 (center), y: 1.5 (about eye level in meters), z: -2 (two meters in front of you)
                            sphereModel.position = SIMD3(x: 0, y: 1.5, z: -2)
                            
                            // 4. Add the sphere to the RealityView content
                            content.add(sphereModel)
                // Put skybox here.  See example in World project available at
                // https://developer.apple.com/
            }
        }
    }
    struct SphereView: View {
        var body: some View {
            RealityView { content in
                let model = ModelEntity(mesh: .generateSphere(radius: 0.5), materials: [SimpleMaterial(color: .red, isMetallic: true)])
                
                content.add(model)
            }
        }
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}
