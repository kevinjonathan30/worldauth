//
//  MeshAnchorGenerator.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/02/06.
//

import RealityKit
import ARKit

/// Handles anchors from `SceneReconstructionProvider` and creates entities on these anchors.
class MeshAnchorGenerator {
    var root: Entity
    private var anchors: [UUID: Entity] = [:]

    init(root: Entity) {
        self.root = root
    }

    #if os(visionOS)
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
    #else
    func run(_ sceneRec: Any) async {
        // VisionOS logic not supported on iOS.
        print("Scene reconstruction is not available on this platform.")
    }
    #endif
}
