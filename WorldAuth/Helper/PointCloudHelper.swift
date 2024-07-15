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
        let header = "ply\n" +
        "format ascii 1.0\n" +
        "element vertex \(points.count)\n" +
        "property float x\n" +
        "property float y\n" +
        "property float z\n" +
        "property uchar red\n" +
        "property uchar green\n" +
        "property uchar blue\n" +
        "property uchar alpha\n" +
        "element face 0\n" + // No faces
        "property list uchar int vertex_indices\n" + // Omit face and vertex indices
        "end_header\n"
        
        var body = ""
        
        for point in points {
            var red: CGFloat = 0.0
            var green: CGFloat = 0.0
            var blue: CGFloat = 0.0
            var alpha: CGFloat = 0.0
            
            point.color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            
            let redByte = UInt8(red * 255)
            let greenByte = UInt8(green * 255)
            let blueByte = UInt8(blue * 255)
            let alphaByte = UInt8(alpha * 255)
            
            body += "\(point.position.x) \(point.position.y) \(point.position.z) \(redByte) \(greenByte) \(blueByte) \(alphaByte)\n"
        }
        
        return header + body
    }
}
