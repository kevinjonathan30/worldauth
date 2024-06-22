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
    @Binding var pointColor: Color
    @Binding var showPointCloud: Bool
    @Binding var showMesh: Bool
    @Binding var isIdealDistance: DistanceState
}

extension ARSceneView: UIViewRepresentable {
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.rendersMotionBlur = false
        arView.rendersCameraGrain = false
        arView.automaticallyUpdatesLighting = false
        return arView
    }
    
    func makeCoordinator() -> Self.Coordinator {
        Self.Coordinator(
            scene: self.$scene,
            pointColor: self.$pointColor,
            showPointCloud: self.$showPointCloud,
            showMesh: self.$showMesh,
            isIdealDistance: self.$isIdealDistance
        )
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        if uiView.session != self.session {
            uiView.session.delegate = nil
            uiView.session = self.session
            uiView.session.delegate = context.coordinator
        }
        uiView.scene = self.scene
    }
    
    static func dismantleUIView(_ uiView: ARSCNView, coordinator: Coordinator) {
        uiView.session.pause()
    }
}

extension ARSceneView {
    final class Coordinator: NSObject {
        @Binding var scene: SCNScene
        @Binding var pointColor: Color
        @Binding var showPointCloud: Bool
        @Binding var showMesh: Bool
        @Binding var isIdealDistance: DistanceState
        var knownAnchors = [UUID: SCNNode]()
        
        init(scene: Binding<SCNScene>, pointColor: Binding<Color>, showPointCloud: Binding<Bool>, showMesh: Binding<Bool>, isIdealDistance: Binding<DistanceState>) {
            self._scene = scene
            self._pointColor = pointColor
            self._showPointCloud = showPointCloud
            self._showMesh = showMesh
            self._isIdealDistance = isIdealDistance
        }
    }
}

extension ARSceneView.Coordinator: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Clear the existing point cloud and mesh nodes
            self.scene.rootNode.enumerateChildNodes { (node, _) in
                if node.name == "PointCloud" || node.name == "Mesh" {
                    node.removeFromParentNode()
                }
            }
        
        // Add point cloud node if showPointCloud is true
        if self.showPointCloud {
            guard let pointCloud = frame.rawFeaturePoints else { return }
            let pointCloudNode = PointCloudHelper.createPointCloudNode(from: pointCloud, color: self.pointColor)
            pointCloudNode.name = "PointCloud"
            self.scene.rootNode.addChildNode(pointCloudNode)
        }

        // Add mesh node if showMesh is true
        if self.showMesh {
            let meshAnchors = frame.anchors.compactMap { $0 as? ARMeshAnchor }
            for anchor in meshAnchors {
                let scnGeometry = SCNGeometry(from: anchor.geometry)
                
                let defaultMaterial = SCNMaterial()
                defaultMaterial.fillMode = .lines
                defaultMaterial.diffuse.contents = self.pointColor.cgColor
                scnGeometry.materials = [defaultMaterial]

                let meshNode = SCNNode(geometry: scnGeometry)
                meshNode.name = "Mesh"
                meshNode.simdTransform = anchor.transform
                
                self.scene.rootNode.addChildNode(meshNode)
                
                self.knownAnchors[anchor.identifier] = meshNode
            }
        }
        
        guard let sceneDepth = frame.smoothedSceneDepth ?? frame.sceneDepth else { return }
        let depthPixelBuffer = sceneDepth.depthMap
        getDistanceInMeters(pixelBuffer: depthPixelBuffer)
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
        let _ = CIImage(cvPixelBuffer: pixelBuffer).oriented(.right)
                    
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
                    
        let centerX = width / 2
        let centerY = height / 2

        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)?.assumingMemoryBound(to: Float32.self)
                    
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let pixelIndex = Int(centerY) * bytesPerRow / MemoryLayout<Float32>.stride + Int(centerX)
                    
        let depthValue = baseAddress?[pixelIndex]
                    
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
                    
        if let depthValue = depthValue {
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
}


#Preview {
    ARSceneView(
        session: .constant(ARSession()),
        scene: .constant(SCNScene()),
        pointColor: .constant(.white),
        showPointCloud: .constant(true),
        showMesh: .constant(false),
        isIdealDistance: .constant(.normal)
    )
}
