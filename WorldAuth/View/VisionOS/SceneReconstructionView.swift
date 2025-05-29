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
    @ObservedObject private var pointCloudManager = PointCloudManager.shared
    @State private var pointCloudGenerator: SceneReconstructionPointCloudGenerator?
    
    var body: some View {
        ZStack {
            // Main AR View - now clean and focused only on scanning
            RealityView { content in
                let root = Entity()
                let arSession = ARKitSession()
                let sceneReconstruction = SceneReconstructionProvider()
                
                Task {
                    let generator = SceneReconstructionPointCloudGenerator(root: root)
                    await MainActor.run {
                        pointCloudGenerator = generator
                        pointCloudManager.pointCloudGenerator = generator
                    }
                    
                    guard SceneReconstructionProvider.isSupported else {
                        await MainActor.run {
                            pointCloudManager.debugText = "SceneReconstructionProvider is not supported on this device."
                        }
                        LoggerHelper.logInfo(
                            parameters: [
                                .message: "SceneReconstructionProvider is not supported on this device.",
                            ]
                        )
                        return
                    }
                    
                    do {
                        try await arSession.run([sceneReconstruction])
                        await MainActor.run {
                            pointCloudManager.debugText = "Scene reconstruction active. Move around to scan the environment..."
                        }
                    } catch let error as ARKitSession.Error {
                        await MainActor.run {
                            pointCloudManager.debugText = "ARKit Error: \(error.localizedDescription)"
                        }
                        LoggerHelper.logError(
                            parameters: [
                                .message: "Encountered an error while running providers: \(error.localizedDescription)",
                            ]
                        )
                    } catch {
                        await MainActor.run {
                            pointCloudManager.debugText = "Unexpected Error: \(error.localizedDescription)"
                        }
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
            
            // Minimal overlay showing only essential scanning feedback
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scanning...")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if pointCloudManager.pointCount > 0 {
                            Text("\(pointCloudManager.pointCount) points")
                                .font(.caption)
                                .foregroundColor(.cyan)
                        }
                        
                        Text("Return to main view to export")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(12)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    
                    Spacer()
                }
                .padding(.top, 50)
                .padding(.leading, 20)
                
                Spacer()
            }
        }
    }
}

#Preview {
    SceneReconstructionView()
}
