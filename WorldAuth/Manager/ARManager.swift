//
//  ARManager.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/01/07.
//

import Foundation
import ARKit

actor ARManager: NSObject, ARSessionDelegate, ObservableObject {
    
    @MainActor let sceneView = ARSCNView()
    @MainActor private var isProcessing = false
    @MainActor @Published var isCapturing = false
    @MainActor let geometryNode = SCNNode()
    @MainActor let pointCloud = PointCloud()
    
    @MainActor
    override init() {
        super.init()
        
        sceneView.session.delegate = self
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
        configuration.planeDetection = [.horizontal]
        configuration.sceneReconstruction = .mesh
        sceneView.session.run(configuration)
        
        sceneView.scene.rootNode.addChildNode(geometryNode)
    }
    
    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        Task { await process(frame: frame) }
    }
    
    @MainActor
    private func process(frame: ARFrame) async {
        guard !isProcessing && isCapturing else { return }
        
        isProcessing = true
        await pointCloud.process(frame: frame)
        await updateGeometry()
        isProcessing = false
    }
    
    func updateGeometry() async {
        let vertices = await pointCloud.vertices.values.enumerated().filter { index, _ in
            index % 10 == 9
        }.map { $0.element }
        
        let vertexSource = SCNGeometrySource(vertices: vertices.map { $0.position })
        
        let colorData = Data(bytes: vertices.map { $0.color },
                             count: MemoryLayout<simd_float4>.size * vertices.count)
        
        let colorSource = SCNGeometrySource(data: colorData,
                                            semantic: .color,
                                            vectorCount: vertices.count,
                                            usesFloatComponents: true,
                                            componentsPerVector: 4,
                                            bytesPerComponent: MemoryLayout<Float>.size,
                                            dataOffset: 0,
                                            dataStride: MemoryLayout<SIMD4<Float>>.size)
        
        let pointIndices: [UInt32] = Array(0..<UInt32(vertices.count))
        let element = SCNGeometryElement(indices: pointIndices, primitiveType: .point)
        
        element.maximumPointScreenSpaceRadius = 15
        
        let geometry = SCNGeometry(sources: [vertexSource, colorSource],
                                   elements: [element])
        geometry.firstMaterial?.isDoubleSided = true
        geometry.firstMaterial?.lightingModel = .constant
        
        Task { @MainActor in
            geometryNode.geometry = geometry
        }
    }
}
