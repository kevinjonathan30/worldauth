//
//  PointCloudHelper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/06.
//

import SwiftUI
import ARKit

struct PointCloudHelper {
    static func extractVertices(from geometry: ARMeshGeometry) -> [SIMD3<Float>] {
        let vertexCount = geometry.vertices.count
        var vertices: [SIMD3<Float>] = []
        
        for vertexIndex in 0..<vertexCount {
            let vertex = geometry.vertex(at: UInt32(vertexIndex))
            vertices.append(vertex)
        }
        
        return vertices
    }
    
    static func createPlyString(from points: [(position: SIMD3<Float>, color: UIColor)]) -> String {
        var body = ""
        
        for point in points {
            body += "\(point.position.x) \(point.position.y) \(point.position.z)\n"
        }
        
        return body
    }
}
