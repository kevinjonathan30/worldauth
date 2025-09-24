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
    
    @State private var cameraAuthorized = false
    
    var onFinishRecording: ((String, String, UIImage?) -> Void)?
    
    var body: some View {
        ZStack {
            if cameraAuthorized {
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
            } else {
                VStack(spacing: 20) {
                    Text("Camera Permission Required")
                        .font(.title2)
                        .bold()
                        .multilineTextAlignment(.center)
                    
                    Text("WorldAuth needs access to your camera to scan the room and enable authentication. Please enable camera access in Settings.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                        Text("Open Settings")
                            .bold()
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding()
            }
        }
        .onAppear {
            checkCameraAuthorization()
            let configuration = ARWorldTrackingConfiguration()
            configuration.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
            configuration.planeDetection = [.horizontal]
            configuration.sceneReconstruction = .mesh
            arManager.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
        .onDisappear {
            Task {
                arManager.sceneView.session.pause()
                await arManager.resetPointCloud()
            }
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
                    .modifier(SymbolTransitionModifier())
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
        .padding(.bottom, useNewPaddingIfAvailable())
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
    private func useNewPaddingIfAvailable() -> CGFloat {
        if #available(iOS 26.0, *) {
            return 80
        } else {
            return 20
        }
    }
    
    private func getIconByTakePointCloudState() -> String {
        return arManager.isCapturing ? "stop.circle.fill" : "record.circle.fill"
    }
    
    func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraAuthorized = true
        case .notDetermined:
            requestCameraAccess()
        case .denied, .restricted:
            cameraAuthorized = false
        @unknown default:
            cameraAuthorized = false
        }
    }
    
    func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                cameraAuthorized = granted
            }
        }
    }
}

// MARK: Handler

private extension ARContainerView {
    private func handleTakePointCloudButtonEvent() {
        if arManager.isCapturing {
            Task {
                let plyString = await PLYFile(pointCloud: arManager.pointCloud).exportBothToPlyString()
                arManager.isCapturing = false
                let recordStartSoundID: SystemSoundID = 1118
                AudioServicesPlaySystemSound(recordStartSoundID)
                
                var capturedImage: UIImage? = nil
                if let currentFrame = arManager.sceneView.session.currentFrame {
                    let image = CIImage(cvPixelBuffer: currentFrame.capturedImage)
                    let context = CIContext()
                    if let cgImage = context.createCGImage(image, from: image.extent) {
                        capturedImage = UIImage(cgImage: cgImage).rotated(by: 90)
                    }
                }
                arManager.sceneView.session.pause()
                await arManager.resetPointCloud()
                onFinishRecording?(plyString.0, plyString.1, capturedImage)
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
    func onFinishRecording(_ onFinishRecording: @escaping((String, String, UIImage?) -> Void)) -> Self {
        var copy = self
        copy.onFinishRecording = onFinishRecording
        return copy
    }
}

#Preview {
    ARContainerView(viewState: .constant(.loaded))
}
