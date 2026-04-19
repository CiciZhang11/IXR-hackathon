import SwiftUI
import RealityKit

struct ContentView: View {
    @Environment(AppModel.self) var appModel
    
    // This environment variable lets us launch the 3D space programmatically
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    var body: some View {
        VStack(spacing: 20) {
            Text("Radar Controls")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Follow the glowing arrow.")
                .foregroundStyle(.secondary)
        }
        .padding(40)
        // The Glass UI Ornament!
        .ornament(attachmentAnchor: .scene(.top), contentAlignment: .center) {
            VStack(spacing: 4) {
                Text("SIGNAL STRENGTH")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                // Color changes dynamically based on strength!
                Text("\(appModel.signalPercentage)%")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(appModel.signalPercentage > 80 ? .green : .primary)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .glassBackgroundEffect() // Native frosted glass look
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomOrnament) {
                HStack(spacing: 24) {
                    
                    // Tool 1: The Sound Picker
                    @Bindable var appModelBindable = appModel
                    Picker("Sound", selection: $appModelBindable.selectedSound) {
                        ForEach(appModel.availableSounds, id: \.self) { sound in
                            Text(sound).tag(sound)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    // Tool 2: The Immersion Mode Toggle
                    ToggleImmersiveSpaceButton()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .task {
            // Auto-launch the 3D arrow space the moment the app opens
            if appModel.immersiveSpaceState == .closed {
                await openImmersiveSpace(id: appModel.immersiveSpaceID)
            }
        }
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
        .environment(AppModel())
}
