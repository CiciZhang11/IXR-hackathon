import SwiftUI
import RealityKit
import simd
import UIKit

struct ImmersiveView: View {
    @Environment(AppModel.self) private var appModel

    @State private var arrowOrigin: SIMD3<Float> = SIMD3(x: 0, y: 1.2, z: -0.5)
    @State private var targetPosition: SIMD3<Float> = SIMD3(x: 0, y: 1.2, z: -2.0)
    @State private var arrowPercentage: Float = 0.8

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

            let distanceMeters = max(0.25, Float(appModel.targetDistanceMeters ?? 1.5))
            let relativeBearing = Float((appModel.targetRelativeBearingDegrees ?? 0) * .pi / 180.0)

            targetPosition.x = arrowOrigin.x + sin(relativeBearing) * distanceMeters
            targetPosition.y = arrowOrigin.y
            targetPosition.z = arrowOrigin.z - cos(relativeBearing) * distanceMeters

            arrowContainer.look(at: targetPosition, from: arrowOrigin, relativeTo: nil)

            let totalDistance = distance(arrowOrigin, targetPosition)
            let physicalLength = max(0.15, totalDistance * arrowPercentage)

            shaft.scale.y = physicalLength
            shaft.position.z = -(physicalLength / 2.0)
            tip.position.z = -physicalLength
        }
        .onAppear {
            appModel.startLocationListening()
        }
        .onDisappear {
            appModel.stopLocationListening()
        }
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
}
