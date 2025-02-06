//
//  ARContainerView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/01/07.
//

import ARKit
import SwiftUI
import Combine

struct ARContainerView: View {
    @StateObject var arManager = ARManager()
    @Binding var viewState: ViewState
    @State private var isCoachingActive = false
    
    var onFinishRecording: ((String) -> Void)?
    
    var body: some View {
        ZStack {
            UIViewWrapper(view: arManager.sceneView)
                .accessibilityElement()
                .accessibilityLabel(Text("AR Scene View", comment: "Accessibility label for AR scene view"))
                .accessibilityHint(Text("Displays augmented reality content", comment: "Accessibility hint for AR scene view"))
            
            CoachingOverlayView(sceneView: arManager.sceneView, isCoachingActive: $isCoachingActive)
                .accessibilityElement()
                .accessibilityLabel(Text("AR Coaching View", comment: "Accessibility label for AR coaching view"))
                .accessibilityHint(Text("Move your iPhone slowly", comment: "Accessibility hint for AR coaching view"))
            
            loadingView()
            
            takePointCloudButton()
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
            .disabled(viewState == .fail || isCoachingActive)
            .opacity(isCoachingActive ? 0 : 1)
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
        return arManager.isCapturing ? "stop.circle.fill" : "record.circle.fill"
    }
}

// MARK: Handler

private extension ARContainerView {
    private func handleTakePointCloudButtonEvent() {
        if arManager.isCapturing {
            Task {
                let plyString = try await PLYFile(pointCloud: arManager.pointCloud).exportToPlyString()
                arManager.isCapturing = false
                let recordStartSoundID: SystemSoundID = 1118
                AudioServicesPlaySystemSound(recordStartSoundID)
                onFinishRecording?(plyString)
            }
        } else {
            arManager.isCapturing = true
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
    func onFinishRecording(_ onFinishRecording: @escaping((String) -> Void)) -> Self {
        var copy = self
        copy.onFinishRecording = onFinishRecording
        return copy
    }
}

#Preview {
    ARContainerView(viewState: .constant(.loaded))
}
