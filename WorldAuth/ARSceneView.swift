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
        ARSCNView(frame: .zero)
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
}

extension ARSceneView {
    final class Coordinator: NSObject {
        @Binding var scene: SCNScene
        @Binding var pointColor: Color
        @Binding var showPointCloud: Bool
        @Binding var showMesh: Bool
        @Binding var lineColor: Color
        var knownAnchors = [UUID: SCNNode]()

        init(scene: Binding<SCNScene>, pointColor: Binding<Color>, showPointCloud: Binding<Bool>, showMesh: Binding<Bool>, lineColor: Binding<Color> = .constant(.white)) {
            self._scene = scene
            self._pointColor = pointColor
            self._showPointCloud = showPointCloud
            self._showMesh = showMesh
            self._lineColor = lineColor
        }
    }
}


func createPointCloudNode(from pointCloud: ARPointCloud, color: Color, pointSize: CGFloat = 0.005) -> SCNNode {
    let node = SCNNode()

    for index in 0..<pointCloud.__count {
        let point = pointCloud.points[index]
        let vector = SCNVector3Make(point.x, point.y, point.z)
        let sphere = SCNSphere(radius: pointSize)
        sphere.firstMaterial?.diffuse.contents = color.cgColor
        sphere.firstMaterial?.lightingModel = .constant
        let pointNode = SCNNode(geometry: sphere)
        pointNode.position = vector
        node.addChildNode(pointNode)
    }

    return node
}

extension ARSceneView.Coordinator: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Clear the existing point cloud and mesh nodes
        scene.rootNode.enumerateChildNodes { (node, _) in
            if node.name == "PointCloud" || node.name == "Mesh" {
                node.removeFromParentNode()
            }
        }

        // Add point cloud node if showPointCloud is true
        if showPointCloud {
            guard let pointCloud = frame.rawFeaturePoints else { return }
            let pointCloudNode = createPointCloudNode(from: pointCloud, color: pointColor)
            pointCloudNode.name = "PointCloud"
            scene.rootNode.addChildNode(pointCloudNode)
        }

        // Add mesh node if showMesh is true
        if showMesh {
            let meshAnchors = frame.anchors.compactMap { $0 as? ARMeshAnchor }
            for anchor in meshAnchors {
                let scnGeometry = SCNGeometry(from: anchor.geometry)

                let defaultMaterial = SCNMaterial()
                defaultMaterial.fillMode = .lines
                defaultMaterial.diffuse.contents = self.lineColor.cgColor
                scnGeometry.materials = [defaultMaterial]

                let meshNode = SCNNode(geometry: scnGeometry)
                meshNode.name = "Mesh"
                meshNode.simdTransform = anchor.transform

                scene.rootNode.addChildNode(meshNode)

                knownAnchors[anchor.identifier] = meshNode
            }
        }
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors.compactMap({ $0 as? ARMeshAnchor }) {
            if let node = knownAnchors[anchor.identifier] {
                node.removeFromParentNode()
                knownAnchors.removeValue(forKey: anchor.identifier)
            }
        }
    }
}

struct ARSceneView_Previews: PreviewProvider {
    static var previews: some View {
        ARSceneView(
            session: .constant(ARSession()),
            scene: .constant(SCNScene()),
            pointColor: .constant(.white),
            showPointCloud: .constant(true),
            showMesh: .constant(false)
        )
    }
}
