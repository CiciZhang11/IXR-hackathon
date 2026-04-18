import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    // Access the AppModel so we can change the sound setting
    @Environment(AppModel.self) var appModel
    
    @State private var enlarge = false

    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            if let scene = try? await Entity(named: "Scene", in: realityKitContentBundle) {
                content.add(scene)
            }
        } update: { content in
            // Update the RealityKit content when SwiftUI state changes
            if let scene = content.entities.first {
                let uniformScale: Float = enlarge ? 1.4 : 1.0
                scene.transform.scale = [uniformScale, uniformScale, uniformScale]
            }
        }
        .gesture(TapGesture().targetedToAnyEntity().onEnded { _ in
            enlarge.toggle()
        })
        .toolbar {
            ToolbarItemGroup(placement: .bottomOrnament) {
                VStack (spacing: 16) {
                    
                    // NEW: The scrolling Picker to select soundtracks
                    @Bindable var appModelBindable = appModel
                    Picker("Select Sound", selection: $appModelBindable.selectedSound) {
                        ForEach(appModel.availableSounds, id: \.self) { sound in
                            Text(sound).tag(sound)
                        }
                    }
                    .pickerStyle(.menu) // Makes it a nice pinchable dropdown
                    .frame(width: 250)
                    
                    Button {
                        enlarge.toggle()
                    } label: {
                        Text(enlarge ? "Reduce RealityView Content" : "Enlarge RealityView Content")
                    }
                    .animation(.none, value: 0)
                    .fontWeight(.semibold)

                    ToggleImmersiveSpaceButton()
                }
                .padding(.vertical, 8) // Gives the menu a little breathing room
            }
        }
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
        .environment(AppModel())
}
