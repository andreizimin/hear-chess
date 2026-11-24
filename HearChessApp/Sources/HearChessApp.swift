// The hear-chess iPhone app: the iOS layer around the training core.
// It turns real input into session-engine events and carries out the engine's effects.
// Designs: docs/intent/{voice,touch,audio,session}/

import SwiftUI

@main
struct HearChessApp: App {
    @StateObject private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            TrainingView(model: model)
                .onAppear { model.launch() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.appBecameActive() }
        }
    }
}

struct TrainingView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("hear-chess")
                    .font(.largeTitle.bold())
                Text(model.statusText)
                    .font(.title3)
                Text(model.lastSpoken)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                if !model.lastHeard.isEmpty {
                    Text("Heard: \(model.lastHeard)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.white)
            .allowsHitTesting(false)
            // @spec TOUCH-001
            GestureSurface { model.gesture($0) }
                .ignoresSafeArea()
        }
        .persistentSystemOverlays(.hidden)
        .defersSystemGestures(on: .all)
    }
}
