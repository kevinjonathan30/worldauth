//
//  ARSceneView.swift
//  LiDARViewer3D
//
//  Created by TM on 2023/05/04.
//

import ARKit
import SceneKit
import SwiftUI

struct ARSceneView {
    @Binding var session: ARSession
    @Binding var scene: SCNScene
    @Binding var isInitialized: Bool
    @Binding var isTakingPointCloud: Bool
    @Binding var isIdealDistance: DistanceState
    @Binding var viewState: ViewState
}

extension ARSceneView: UIViewRepresentable {
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.rendersMotionBlur = false
        arView.rendersCameraGrain = false
        arView.automaticallyUpdatesLighting = false
        arView.scene = self.scene
        
        return arView
    }
    
    func makeCoordinator() -> Self.Coordinator {
        Self.Coordinator(
            session: self.$session,
            scene: self.$scene,
            isInitialized: self.$isInitialized,
            isTakingPointCloud: self.$isTakingPointCloud,
            isIdealDistance: self.$isIdealDistance,
            viewState: self.$viewState
        )
    }
    
    func updateUIView(_ arView: ARSCNView, context: Context) {
        if arView.session != self.session {
            arView.session.delegate = nil
            arView.session = self.session
            arView.session.delegate = context.coordinator
        }
        context.coordinator.toggleCoachingOverlayIfNeeded(on: arView)
    }
    
    static func dismantleUIView(_ arView: ARSCNView, coordinator: Coordinator) {
        arView.session.pause()
    }
}

extension ARSceneView {
    final class Coordinator: NSObject {
        @Binding var session: ARSession
        @Binding var scene: SCNScene
        @Binding var isInitialized: Bool
        @Binding var isTakingPointCloud: Bool
        @Binding var isIdealDistance: DistanceState
        @Binding var viewState: ViewState
        
        var knownAnchors = [UUID: SCNNode]()
        let defaultMaterial: SCNMaterial = {
            let material = SCNMaterial()
            material.fillMode = .lines
            material.diffuse.contents = UIColor.white
            return material
        }()
        
        init(
            session: Binding<ARSession>,
            scene: Binding<SCNScene>,
            isInitialized: Binding<Bool>,
            isTakingPointCloud: Binding<Bool>,
            isIdealDistance: Binding<DistanceState>,
            viewState: Binding<ViewState>
        ) {
            self._session = session
            self._scene = scene
            self._isInitialized = isInitialized
            self._isTakingPointCloud = isTakingPointCloud
            self._isIdealDistance = isIdealDistance
            self._viewState = viewState
        }
    }
}

extension ARSceneView.Coordinator: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Clear the existing point cloud and mesh nodes
        self.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        
        guard let meshAnchors = session.currentFrame?.anchors.compactMap({ $0 as? ARMeshAnchor }), !meshAnchors.isEmpty else {
            isInitialized = false
            return
        }

        self.isInitialized = true
        
        guard let sceneDepth = frame.smoothedSceneDepth ?? frame.sceneDepth else { return }
        let depthMap = sceneDepth.depthMap
        
        getDistanceInMeters(pixelBuffer: depthMap)
        
        if isTakingPointCloud {
            for anchor in meshAnchors {
                guard anchor.geometry.vertices.count > 0 else { continue }
                let scnGeometry = SCNGeometry(from: anchor.geometry)
                scnGeometry.materials = [defaultMaterial]
                
                let meshNode = SCNNode(geometry: scnGeometry)
                meshNode.name = "Mesh"
                meshNode.simdTransform = anchor.transform
                
                DispatchQueue.main.async {
                    self.scene.rootNode.addChildNode(meshNode)
                }
                self.knownAnchors[anchor.identifier] = meshNode
            }
        }
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors.compactMap({ $0 as? ARMeshAnchor }) {
            if let node = knownAnchors[anchor.identifier] {
                DispatchQueue.main.async {
                    node.removeFromParentNode()
                    self.knownAnchors.removeValue(forKey: anchor.identifier)
                }
            }
        }
    }
    
    func getDistanceInMeters(pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)?.assumingMemoryBound(to: Float32.self) else { return }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let centerX = width / 2
        let centerY = height / 2
        
        guard centerX < width, centerY < height else { return }
        
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
    func toggleCoachingOverlayIfNeeded(on arView: ARSCNView) {
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
        scene: .constant(SCNScene()),
        isInitialized: .constant(false),
        isTakingPointCloud: .constant(false),
        isIdealDistance: .constant(.normal),
        viewState: .constant(.loaded)
    )
}
