//
//  ARContainerView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/07/05.
//

import ARKit
import SwiftUI
import SceneKit
import Combine

struct ARContainerView: View {
    @State private var session: ARSession = ARSession()
    @State private var scene: SCNScene = SCNScene()
    @State private var isIdealDistance: DistanceState = .normal
    @State private var isInitialized = false
    @State private var isTakingPointCloud = false
    @Binding var viewState: ViewState
    
    var onFinishRecording: (([(position: SIMD3<Float>, color: UIColor)]) -> Void)?
    
    var body: some View {
        ZStack {
            DistanceToasterView(isIdealDistance: $isIdealDistance)
            
            ARSceneView(
                session: self.$session,
                scene: self.$scene,
                isInitialized: self.$isInitialized,
                isTakingPointCloud: self.$isTakingPointCloud,
                isIdealDistance: self.$isIdealDistance,
                viewState: self.$viewState
            )
            .accessibilityElement()
            .accessibilityLabel(Text("AR Scene View", comment: "Accessibility label for AR scene view"))
            .accessibilityHint(Text("Displays augmented reality content", comment: "Accessibility hint for AR scene view"))
            
            loadingView()
            
            takePointCloudButton()
        }
        .onAppear {
            let session = ARSession()
            session.run(ARWorldHelper.getARWorldTrackingConfiguration(), options: ARWorldHelper.getARWorldTrackingOptions())
            self.session = session
        }
        .onDisappear {
            self.session.pause()
        }
        .onChange(of: isInitialized) { _ in
            isTakingPointCloud = false
        }
    }
}

// MARK: ViewBuilder

private extension ARContainerView {
    @ViewBuilder
    private func takePointCloudButton() -> some View {
        VStack {
            Spacer()
            
            Button(action: handleTakePointCloudButtonEvent) {
                if isInitialized {
                    Image(systemName: getIconByTakePointCloudState())
                        .foregroundColor(.red)
                        .font(.title)
                        .frame(width: 80, height: 80)
                        .background(Color.white)
                        .clipShape(Circle())
                } else {
                    ProgressView()
                        .tint(.black)
                        .frame(width: 80, height: 80)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
            .padding()
            .disabled(viewState == .fail || !isInitialized)
            .accessibilityElement()
            .accessibilityLabel(Text("Take Room Template Button", comment: "Accessibility label for button"))
            .accessibilityHint(Text("Click this button to scan the room template, and then move the device slowly", comment: "Accessibility hint for button"))
            .accessibilityAddTraits([.isButton])
        }
        .padding(.bottom, 20)
        .transaction { transaction in
            transaction.animation = .none
        }
    }
    
    @ViewBuilder
    private func loadingView() -> some View {
        ZStack {
            Color.black
                .opacity(0.9)
            
            VStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                    .zIndex(999)
                    .padding(.bottom)
                    .accessibilityElement()
                    .accessibilityLabel(Text("Loading Indicator", comment: "Accessibility label for loading indicator"))
                    .accessibilityHint(Text("Indicates that data is loading", comment: "Accessibility hint for loading indicator"))
                
                Text("Loading..")
                    .foregroundStyle(.white)
                    .accessibilityElement()
                    .accessibilityLabel(Text("Loading Text", comment: "Accessibility label for loading text"))
                    .accessibilityHint(Text("Displays loading message", comment: "Accessibility hint for loading text"))
            }
        }
        .zIndex(999)
        .opacity(viewState == .loading ? 1 : 0)
        .animation(.easeInOut(duration: 0.1), value: viewState)
        .accessibilityElement()
        .accessibilityLabel(Text("Loading View", comment: "Accessibility label for view"))
        .accessibilityHint(Text("Loading..", comment: "Accessibility hint for view"))
    }
}

// MARK: Helper

private extension ARContainerView {
    private func getIconByTakePointCloudState() -> String {
        return isTakingPointCloud ? "stop.circle.fill" : "record.circle.fill"
    }
}

// MARK: Handler

private extension ARContainerView {
    private func handleTakePointCloudButtonEvent() {
        guard let meshAnchors = session.currentFrame?.anchors.compactMap({ $0 as? ARMeshAnchor }) else { return }
        
        if isTakingPointCloud {
            var pointsWithColor: [(position: SIMD3<Float>, color: UIColor)] = []
            for anchor in meshAnchors {
                let vertices = PointCloudHelper.extractVertices(from: anchor.geometry)
                
                // Transform vertices to world coordinates based on anchor's transform
                let transformedVertices = vertices.map { vertex -> (position: SIMD3<Float>, color: UIColor) in
                    let positionInLocal = vertex.position
                    let positionInWorld = anchor.transform * SIMD4<Float>(positionInLocal.x, positionInLocal.y, positionInLocal.z, 1)
                    return (position: SIMD3<Float>(positionInWorld.x, positionInWorld.y, positionInWorld.z), color: UIColor(Color.white))
                }
                
                pointsWithColor.append(contentsOf: transformedVertices)
            }
            isTakingPointCloud = false
            let recordStartSoundID: SystemSoundID = 1118
            AudioServicesPlaySystemSound(recordStartSoundID)
            onFinishRecording?(pointsWithColor)
        } else {
            isTakingPointCloud = true
            let recordStartSoundID: SystemSoundID = 1117
            AudioServicesPlaySystemSound(recordStartSoundID)
        }
    }
}

// MARK: Public Modifier

extension ARContainerView {
    
    /// onFinishRecording
    /// - Parameter action: runs an action everytime the recording is finished
    /// - Returns: ARContainerView
    func onFinishRecording(_ onFinishRecording: @escaping(([(position: SIMD3<Float>, color: UIColor)]) -> Void)) -> Self {
        var copy = self
        copy.onFinishRecording = onFinishRecording
        return copy
    }
}

#Preview {
    ARContainerView(viewState: .constant(.loaded))
}
