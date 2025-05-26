//
//  MeshAnchorGenerator.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/02/06.
//

import RealityKit
import ARKit
import SwiftUI

/// Handles anchors from `SceneReconstructionProvider` and creates entities on these anchors.
class MeshAnchorGenerator {
    var root: Entity
    private var anchors: [UUID: Entity] = [:]

    init(root: Entity) {
        self.root = root
    }

    /// Handle anchor update events by adding, updating, or removing anchors.
    @MainActor
    func run(_ sceneRec: SceneReconstructionProvider) async {
        
        for await update in sceneRec.anchorUpdates {
            switch update.event {
            case .added, .updated:
                let entity = anchors[update.anchor.id] ?? {
                    let entity = Entity()
                    root.addChild(entity)
                    anchors[update.anchor.id] = entity
                    return entity
                }()

                let material = SimpleMaterial(color: .white.withAlphaComponent(0.8), isMetallic: false)
                guard let mesh = try? await MeshResource(from: update.anchor) else { return }

                await MainActor.run {
                    entity.components.set(ModelComponent(mesh: mesh, materials: [material]))
                    entity.setTransformMatrix(update.anchor.originFromAnchorTransform, relativeTo: nil)
                }
            case .removed:
                anchors[update.anchor.id]?.removeFromParent()
                anchors[update.anchor.id] = nil
            }
        }
    }
    
    /// Export all anchor meshes as a point cloud in PLY format to the given URL.
    func exportAnchorsToPLY() -> URL? {
        var points: [SIMD3<Float>] = []

        for (_, entity) in anchors {
            guard let model = entity.components[ModelComponent.self] else { continue }
            let transform = entity.transformMatrix(relativeTo: nil)
            
            // Use the bounding box or similar structure to estimate the point positions
            let bounds = model.mesh.bounds
            let min = bounds.min
            let max = bounds.max
            
            // Generate points within the bounding box
            let resolution: Float = 0.05 // Adjust for finer details
            for x in stride(from: min.x, through: max.x, by: resolution) {
                for y in stride(from: min.y, through: max.y, by: resolution) {
                    for z in stride(from: min.z, through: max.z, by: resolution) {
                        let point = SIMD3<Float>(x, y, z)
                        let worldPoint = transform * SIMD4<Float>(point, 1.0)
                        points.append(SIMD3<Float>(worldPoint.x, worldPoint.y, worldPoint.z))
                    }
                }
            }
        }

        // Write points to a PLY file in a temporary location
        var ply = "ply\nformat ascii 1.0\n"
        ply += "element vertex \(points.count)\n"
        ply += "property float x\nproperty float y\nproperty float z\n"
        ply += "end_header\n"
        for point in points {
            ply += "\(point.x) \(point.y) \(point.z)\n"
        }

        let fileName = "exported_mesh.ply"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try ply.write(to: tempURL, atomically: true, encoding: .utf8)
            print("PLY file written successfully to \(tempURL)")
            return tempURL
        } catch {
            print("Error writing PLY file: \(error)")
            return nil
        }
    }
}
