//
//  ARWorldHelper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/06.
//

import Foundation
import ARKit

struct ARWorldHelper {
    static func getARWorldTrackingConfiguration() -> ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.sceneReconstruction = .meshWithClassification
        configuration.planeDetection = [.horizontal]
        configuration.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
        configuration.environmentTexturing = .automatic
        
        return configuration
    }
    
    static func getARWorldTrackingOptions() -> ARSession.RunOptions {
        return [
            .resetSceneReconstruction,
            .resetTracking,
            .removeExistingAnchors,
            .stopTrackedRaycasts
        ]
    }
}
