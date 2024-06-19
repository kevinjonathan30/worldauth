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
        Self.Coordinator(scene: self.$scene, pointColor: self.$pointColor, showPointCloud: self.$showPointCloud, showMesh: self.$showMesh)
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
        var knownAnchors = [UUID: SCNNode]()
        
        init(scene: Binding<SCNScene>, pointColor: Binding<Color>, showPointCloud: Binding<Bool>, showMesh: Binding<Bool>) {
            self._scene = scene
            self._pointColor = pointColor
            self._showPointCloud = showPointCloud
            self._showMesh = showMesh
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
}


#Preview {
    ARSceneView(
        session: .constant(ARSession()),
        scene: .constant(SCNScene()),
        pointColor: .constant(.white),
        showPointCloud: .constant(true),
        showMesh: .constant(false)
    )
}
