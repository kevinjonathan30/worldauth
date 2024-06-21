//
//  PointCloudHelper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/06.
//

import SwiftUI
import ARKit

struct PointCloudHelper {
    static func createPointCloudNode(from pointCloud: ARPointCloud, color: Color, pointSize: CGFloat = 0.005) -> SCNNode {
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
    
    static func extractVertices(from geometry: ARMeshGeometry) -> [SIMD3<Float>] {
        let vertexCount = geometry.vertices.count
        var vertices: [SIMD3<Float>] = []
        vertices.reserveCapacity(vertexCount)
        
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
    
    static func parsePLYVertices(data: Data) -> [PLYVertex]? {
        guard let stringData = String(data: data, encoding: .utf8) else { return nil }
        
        var vertices: [PLYVertex] = []
        var isHeaderFinished = false
        
        // Split lines
        let lines = stringData.components(separatedBy: .newlines)
        
        for line in lines {
            let components = line.components(separatedBy: .whitespaces)
            
            if components.count > 0 {
                if isHeaderFinished {
                    if let x = Float(components[safe: 0] ?? "0"),
                       let y = Float(components[safe: 1] ?? "0"),
                       let z = Float(components[safe: 2] ?? "0"),
                       let red = UInt8(components[safe: 3] ?? "0"),
                       let green = UInt8(components[safe: 4] ?? "0"),
                       let blue = UInt8(components[safe: 5] ?? "0"),
                       let alpha = UInt8(components[safe: 6] ?? "0")
                    {
                        let vertex = PLYVertex(x: x, y: y, z: z, red: red, green: green, blue: blue, alpha: alpha)
                        vertices.append(vertex)
                    }
                } else {
                    if components[safe: 0] ?? "0" == "end_header" {
                        isHeaderFinished = true
                    }
                }
            }
        }
        
        return vertices
    }
    
    static func parsePLYVertices(data: String) -> [PLYVertex]? {
        var vertices: [PLYVertex] = []
        var isHeaderFinished = false
        
        // Split lines
        let lines = data.components(separatedBy: .newlines)
        
        for line in lines {
            let components = line.components(separatedBy: .whitespaces)
            
            if components.count > 0 {
                if isHeaderFinished {
                    if let x = Float(components[safe: 0] ?? "0"),
                       let y = Float(components[safe: 1] ?? "0"),
                       let z = Float(components[safe: 2] ?? "0"),
                       let red = UInt8(components[safe: 3] ?? "0"),
                       let green = UInt8(components[safe: 4] ?? "0"),
                       let blue = UInt8(components[safe: 5] ?? "0"),
                       let alpha = UInt8(components[safe: 6] ?? "0")
                    {
                        let vertex = PLYVertex(x: x, y: y, z: z, red: red, green: green, blue: blue, alpha: alpha)
                        vertices.append(vertex)
                    }
                } else {
                    if components[safe: 0] ?? "0" == "end_header" {
                        isHeaderFinished = true
                    }
                }
            }
        }
        
        return vertices
    }
    
    static func computeHausdorffDistance(vertices1: [PLYVertex], vertices2: [PLYVertex]) -> Float {
        var maxDistance: Float = 0.0
        
        for vertex1 in vertices1 {
            var minDistance: Float = .greatestFiniteMagnitude
            
            for vertex2 in vertices2 {
                let distance = sqrt(pow(vertex1.x - vertex2.x, 2) + pow(vertex1.y - vertex2.y, 2) + pow(vertex1.z - vertex2.z, 2))
                if distance < minDistance {
                    minDistance = distance
                }
            }
            
            if minDistance > maxDistance {
                maxDistance = minDistance
            }
        }
        
        return maxDistance
    }
    
    static func computeChamferDistance(vertices1: [PLYVertex], vertices2: [PLYVertex]) -> Float {
        var sumDistance1: Float = 0.0
        var sumDistance2: Float = 0.0
        
        // Compute the sum of squared distances from each point in vertices1 to the closest point in vertices2
        for vertex1 in vertices1 {
            var minDistance: Float = .greatestFiniteMagnitude
            
            for vertex2 in vertices2 {
                let distance = pow(vertex1.x - vertex2.x, 2) + pow(vertex1.y - vertex2.y, 2) + pow(vertex1.z - vertex2.z, 2)
                if distance < minDistance {
                    minDistance = distance
                }
            }
            
            sumDistance1 += minDistance
        }
        
        // Compute the sum of squared distances from each point in vertices2 to the closest point in vertices1
        for vertex2 in vertices2 {
            var minDistance: Float = .greatestFiniteMagnitude
            
            for vertex1 in vertices1 {
                let distance = pow(vertex1.x - vertex2.x, 2) + pow(vertex1.y - vertex2.y, 2) + pow(vertex1.z - vertex2.z, 2)
                if distance < minDistance {
                    minDistance = distance
                }
            }
            
            sumDistance2 += minDistance
        }
        
        // The Chamfer distance is the average of these two sums
        let chamferDistance = (sumDistance1 / Float(vertices1.count)) + (sumDistance2 / Float(vertices2.count))
        
        return chamferDistance
    }
    
    static func normalizeDistance(_ distance: Float, maxThreshold: Float = 0.7) -> Float {
        return min(distance / maxThreshold, 1.0) // Ensure the normalized distance is capped at 1.0
    }
    
    static func calculateSimilarity(plyFile1URL: URL, plyFile2URL: URL) {
        // Parse PLY files
        guard let file1Data = try? Data(contentsOf: plyFile1URL),
              let file2Data = try? Data(contentsOf: plyFile2URL),
              let file1Vertices = PointCloudHelper.parsePLYVertices(data: file1Data),
              let file2Vertices = PointCloudHelper.parsePLYVertices(data: file2Data) else { return }
        
        // Compute similarity metrics
        let chamferDistance = computeChamferDistance(vertices1: file1Vertices, vertices2: file2Vertices)
        
        // Normalize distances
        let normalizedChamfer = normalizeDistance(chamferDistance)
        
        // Convert to similarity percentage
        let chamferSimilarity = (1.0 - normalizedChamfer) * 100.0
        
        // Print results
        print("Chamfer Distance: \(chamferDistance), Similarity: \(chamferSimilarity)%")
        
        // Overall similarity (average of both metrics)
        print("Overall Similarity: \(chamferSimilarity)%")
    }
    
    static func calculateSimilarity(savedPlyFileURL: URL, currentPlyFileString: String) -> Float? {
        // Parse PLY files
        guard let savedPlyFileData = try? Data(contentsOf: savedPlyFileURL),
              let savedPlyFileVertices = PointCloudHelper.parsePLYVertices(data: savedPlyFileData),
              let currentPlyFileVertices = PointCloudHelper.parsePLYVertices(data: currentPlyFileString) else { return nil }
        
        // Compute similarity metrics
        let chamferDistance = computeChamferDistance(vertices1: savedPlyFileVertices, vertices2: currentPlyFileVertices)
        
        // Normalize distances
        let normalizedChamfer = normalizeDistance(chamferDistance)
        
        // Convert to similarity percentage
        let chamferSimilarity = (1.0 - normalizedChamfer) * 100.0
        
        // Print results
        print("Chamfer Distance: \(chamferDistance), Similarity: \(chamferSimilarity)%")
        
        // Overall similarity (average of both metrics)
        print("Overall Similarity: \(chamferSimilarity)%")
        
        return chamferSimilarity
    }
}
