//
//  SceneReconstructionPointCloudGenerator.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/05/29.
//

import RealityKit
import ARKit
import SwiftUI

/// Handles anchors and extracts point clouds
class SceneReconstructionPointCloudGenerator {
    var root: Entity
    private var meshAnchors: [UUID: Entity] = [:]
    private var pointCloudData: [SIMD3<Float>] = []
    private var pointCloudEntity: Entity?
    
    init(root: Entity) {
        self.root = root
    }
    
    /// Handle anchor update events and extract point clouds from mesh data
    @MainActor
    func run(_ sceneRec: SceneReconstructionProvider) async {
        for await update in sceneRec.anchorUpdates {
            switch update.event {
            case .added, .updated:
                let entity = meshAnchors[update.anchor.id] ?? {
                    let entity = Entity()
                    root.addChild(entity)
                    meshAnchors[update.anchor.id] = entity
                    return entity
                }()
                
                // Create mesh visualization
                let material = SimpleMaterial(color: .white.withAlphaComponent(0.3), isMetallic: false)
                guard let mesh = try? await MeshResource(from: update.anchor) else { return }
                
                await MainActor.run {
                    entity.components.set(ModelComponent(mesh: mesh, materials: [material]))
                    entity.setTransformMatrix(update.anchor.originFromAnchorTransform, relativeTo: nil)
                }
                
                await extractPointsFromMesh(update.anchor)
                
            case .removed:
                meshAnchors[update.anchor.id]?.removeFromParent()
                meshAnchors[update.anchor.id] = nil
            }
        }
    }
    
    /// Extract point cloud data from mesh anchor
    @MainActor
    private func extractPointsFromMesh(_ anchor: MeshAnchor) async {
        guard let mesh = try? await MeshResource(from: anchor) else { return }
        
        let transform = anchor.originFromAnchorTransform
        
        // Extract vertices from the mesh
        let meshContents = mesh.contents
        guard let positions = meshContents.models.first?.parts.first?.positions else { return }
        
        var newPoints: [SIMD3<Float>] = []
        
        // Convert mesh vertices to world coordinates
        for position in positions {
            let localPoint = SIMD4<Float>(position.x, position.y, position.z, 1.0)
            let worldPosition = transform * localPoint
            let point = SIMD3<Float>(worldPosition.x, worldPosition.y, worldPosition.z)
            newPoints.append(point)
        }
        
        // Sample points if there are too many (for performance)
        // TODO: test this
        let maxPointsPerMesh = 1000
        
        if newPoints.count > maxPointsPerMesh {
            let step = newPoints.count / maxPointsPerMesh
            newPoints = stride(from: 0, to: newPoints.count, by: step).map { newPoints[$0] }
        }
        
        pointCloudData.append(contentsOf: newPoints)
        print("Added \(newPoints.count) points from mesh. Total: \(pointCloudData.count)")
    }
    
    /// Export point cloud data as array of 3D points
    func exportPointCloud() -> [SIMD3<Float>] {
        return pointCloudData
    }
    
    /// Export point cloud data as PLY format string
    func exportPointCloudAsPLY() -> String {
        var vertexData = ""
        for point in pointCloudData {
            vertexData += "\(point.x) \(point.y) \(point.z)\n"
        }
        
        return vertexData
    }
    
//    func exportPointCloudAsPLY() -> String {
//        var plyContent = """
//            ply
//            format ascii 1.0
//            element vertex \(pointCloudData.count)
//            property float x
//            property float y
//            property float z
//            end_header
//            """
//        
//        for point in pointCloudData {
//            let posX = point.x
//            let posY = point.y
//            let posZ = point.z
//            
//            plyContent += "\n\(posX) \(posY) \(posZ)"
//        }
//        
//        return plyContent
//    }
    
    /// Clear all point cloud data
    @MainActor
    func clearPointCloud() {
        pointCloudData.removeAll()
        pointCloudData = []

        pointCloudEntity?.removeFromParent()
        pointCloudEntity = nil

        for (_, entity) in meshAnchors {
            entity.removeFromParent()
        }
        meshAnchors.removeAll()

        print("Point cloud and mesh visuals cleared")
    }
}
