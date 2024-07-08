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
    @State var session: ARSession = ARSession()
    @State var scene: SCNScene = SCNScene()
    @State private var isIdealDistance: DistanceState = .normal
    @State var isTakingPointCloud = false
    @State var isScreenBlack = false
    @State var pointCloudData: [(position: SIMD3<Float>, color: UIColor)] = []
    @Binding var viewState: ViewState
    
    var onFinishRecording: (([(position: SIMD3<Float>, color: UIColor)]) -> Void)?
    
    var body: some View {
        ZStack {
            DistanceToasterView(isIdealDistance: $isIdealDistance)
            
            ARSceneView(
                session: self.$session,
                scene: self.$scene,
                isIdealDistance: self.$isIdealDistance,
                viewState: self.$viewState
            )
            
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
    }
}

// MARK: ViewBuilder

private extension ARContainerView {
    @ViewBuilder
    private func takePointCloudButton() -> some View {
        VStack {
            Spacer()
            
            Button(action: handleTakePointCloudButtonEvent) {
                Image(systemName: getIconByTakePointCloudState())
                    .foregroundColor(.red)
                    .font(.title)
                    .frame(width: 80, height: 80)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .padding()
            .disabled(viewState == .fail)
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
                
                Text("Loading Data..")
                    .foregroundStyle(.white)
            }
        }
        .zIndex(999)
        .opacity(viewState == .loading ? 1 : 0)
        .animation(.easeInOut(duration: 0.1), value: viewState)
        .accessibilityLabel(Text("Loading View", comment: "Accessibility label for view"))
        .accessibilityHint(Text("Loading Data", comment: "Accessibility hint for view"))
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
        guard let anchors = self.session.currentFrame?.anchors,
        !anchors.compactMap({ $0 as? ARMeshAnchor }).isEmpty else { return }
        
        if isTakingPointCloud {
            isTakingPointCloud = false
            isScreenBlack = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isScreenBlack = false
            }
            let recordStartSoundID: SystemSoundID = 1118
            AudioServicesPlaySystemSound(recordStartSoundID)
            onFinishRecording?(pointCloudData)
        } else {
            isTakingPointCloud = true
            savePlyFile()
            let recordStartSoundID: SystemSoundID = 1117
            AudioServicesPlaySystemSound(recordStartSoundID)
        }
    }
    
    private func savePlyFile() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !isTakingPointCloud {
                timer.invalidate()
            } else {
                guard let anchors = self.session.currentFrame?.anchors else { return }
                let meshAnchors = anchors.compactMap { $0 as? ARMeshAnchor }
                var pointsWithColor: [(position: SIMD3<Float>, color: UIColor)] = []
                for anchor in meshAnchors {
                    let vertices = PointCloudHelper.extractVertices(from: anchor.geometry)
                    pointsWithColor.append(contentsOf: vertices.map { (position: $0, color: UIColor(Color.white)) })
                }
                pointCloudData = pointsWithColor
            }
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
