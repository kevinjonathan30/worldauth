//
//  SceneReconstructionView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/02/06.
//

import SwiftUI
import RealityKit
import ARKit

struct SceneReconstructionView: View {
    var body: some View {
        #if os(visionOS)
        RealityView { content in
            let root = Entity()
            let arSession = ARKitSession()
            let sceneReconstruction = SceneReconstructionProvider()

            Task {
                let generator = MeshAnchorGenerator(root: root)

                guard SceneReconstructionProvider.isSupported else {
                    LoggerHelper.logInfo(
                        parameters: [
                            .message: "SceneReconstructionProvider is not supported on this device.",
                        ]
                    )
                    return
                }

                do {
                    try await arSession.run([sceneReconstruction])
                } catch let error as ARKitSession.Error {
                    LoggerHelper.logError(
                        parameters: [
                            .message: "Encountered an error while running providers: \(error.localizedDescription)",
                        ]
                    )
                } catch {
                    LoggerHelper.logError(
                        parameters: [
                            .message: "Unexpected error: \(error.localizedDescription)",
                        ]
                    )
                }

                await generator.run(sceneReconstruction)
            }

            content.add(root)
        }
        #else
        Text("Scene reconstruction is not available on this platform.")
        #endif
    }
}

#Preview {
    SceneReconstructionView()
}
