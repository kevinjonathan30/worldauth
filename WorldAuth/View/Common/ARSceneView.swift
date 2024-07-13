//
//  ARSceneView.swift
//  LiDARViewer3D
//
//  Created by TM on 2023/05/04.
//

import ARKit
import RealityKit
import SwiftUI

struct ARSceneView {
    @Binding var session: ARSession
    @Binding var isIdealDistance: DistanceState
    @Binding var viewState: ViewState
}

extension ARSceneView: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = false
        arView.debugOptions.insert(.showSceneUnderstanding)
        
        return arView
    }
    
    func makeCoordinator() -> Self.Coordinator {
        Self.Coordinator(
            session: self.$session,
            isIdealDistance: self.$isIdealDistance,
            viewState: self.$viewState
        )
    }
    
    func updateUIView(_ arView: ARView, context: Context) {
        if arView.session != self.session {
            arView.session.delegate = nil
            arView.session = self.session
            arView.session.delegate = context.coordinator
        }
        context.coordinator.toggleCoachingOverlayIfNeeded(on: arView)
    }
    
    static func dismantleUIView(_ arView: ARView, coordinator: Coordinator) {
        arView.session.pause()
    }
}

extension ARSceneView {
    final class Coordinator: NSObject {
        @Binding var session: ARSession
        @Binding var isIdealDistance: DistanceState
        @Binding var viewState: ViewState
        
        init(session: Binding<ARSession>, isIdealDistance: Binding<DistanceState>, viewState: Binding<ViewState>) {
            self._session = session
            self._isIdealDistance = isIdealDistance
            self._viewState = viewState
        }
    }
}

extension ARSceneView.Coordinator: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let sceneDepth = frame.smoothedSceneDepth ?? frame.sceneDepth else { return }
        let depthMap = sceneDepth.depthMap
        
        getDistanceInMeters(pixelBuffer: depthMap)
    }
    
    func getDistanceInMeters(pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)?.assumingMemoryBound(to: Float32.self) else { return }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let centerX = width / 2
        let centerY = height / 2
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let pixelIndex = centerY * bytesPerRow / MemoryLayout<Float32>.stride + centerX
        
        let depthValue = baseAddress[pixelIndex]
        
        let distanceInMeters = Double(depthValue)
        
        if distanceInMeters < 0.3 {
            isIdealDistance = .close
        } else if distanceInMeters > 2 {
            isIdealDistance = .far
        } else {
            isIdealDistance = .normal
        }
    }
}

extension ARSceneView.Coordinator: ARCoachingOverlayViewDelegate {
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        viewState = .fail
    }
    
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        coachingOverlayView.removeFromSuperview()
        viewState = .loaded
    }
    
    // Toggle coaching overlay based on plane detection
    func toggleCoachingOverlayIfNeeded(on arView: ARView) {
        let coachingOverlayView: ARCoachingOverlayView = ARCoachingOverlayView()
        coachingOverlayView.session = arView.session
        coachingOverlayView.goal = .verticalPlane
        coachingOverlayView.autoresizingMask = [
            .flexibleWidth, .flexibleHeight
        ]
        coachingOverlayView.delegate = self
        coachingOverlayView.center = arView.center
        coachingOverlayView.tag = 51
        coachingOverlayView.layer.zPosition = 51
        coachingOverlayView.isAccessibilityElement = true
        coachingOverlayView.accessibilityLabel = "AR Coaching View"
        coachingOverlayView.accessibilityHint = "Please move your device around slowly"
        
        if let alreadyExistView = arView.viewWithTag(51) {
            alreadyExistView.removeFromSuperview()
        }
        arView.addSubview(coachingOverlayView)
    }
}

#Preview {
    ARSceneView(
        session: .constant(ARSession()),
        isIdealDistance: .constant(.normal),
        viewState: .constant(.loaded)
    )
}
