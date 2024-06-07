//
//  PointCloudHelper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/06.
//

import UIKit

struct PointCloudHelper {
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
        "end_header\n"
        
        var body = ""
        
        for point in points {
            let red = UInt8((point.color.cgColor.components?[0] ?? 0.0) * 255)
            let green = UInt8((point.color.cgColor.components?[1] ?? 0.0) * 255)
            let blue = UInt8((point.color.cgColor.components?[2] ?? 0.0) * 255)
            
            body += "\(point.position.x) \(point.position.y) \(point.position.z) \(red) \(green) \(blue)\n"
        }
        
        return header + body
    }
    
    static func parsePLYVertices(data: Data) -> [PLYVertex]? {
        guard let stringData = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        var vertices: [PLYVertex] = []
        var isHeaderFinished = false
        
        // Split lines
        let lines = stringData.components(separatedBy: .newlines)
        
        for line in lines {
            let components = line.components(separatedBy: .whitespaces)
            
            if components.count > 0 {
                if isHeaderFinished {
                    if let x = Float(components[0]),
                       let y = Float(components[1]),
                       let z = Float(components[2]),
                       let red = UInt8(components[3]),
                       let green = UInt8(components[4]),
                       let blue = UInt8(components[5])
                    {
                        let vertex = PLYVertex(x: x, y: y, z: z, red: red, green: green, blue: blue)
                        vertices.append(vertex)
                    }
                } else {
                    if components[0] == "end_header" {
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
                    if let x = Float(components[0]),
                       let y = Float(components[1]),
                       let z = Float(components[2]),
                       let red = UInt8(components[3]),
                       let green = UInt8(components[4]),
                       let blue = UInt8(components[5])
                    {
                        let vertex = PLYVertex(x: x, y: y, z: z, red: red, green: green, blue: blue)
                        vertices.append(vertex)
                    }
                } else {
                    if components[0] == "end_header" {
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
        let hausdorffDistance1 = computeHausdorffDistance(vertices1: file1Vertices, vertices2: file2Vertices)
        let hausdorffDistance2 = computeHausdorffDistance(vertices1: file2Vertices, vertices2: file1Vertices)
        let hausdorffDistance = max(hausdorffDistance1, hausdorffDistance2)
        let chamferDistance = computeChamferDistance(vertices1: file1Vertices, vertices2: file2Vertices)
        
        // Normalize distances
        let normalizedHausdorff = normalizeDistance(hausdorffDistance)
        let normalizedChamfer = normalizeDistance(chamferDistance)
        
        // Convert to similarity percentage
        let hausdorffSimilarity = (1.0 - normalizedHausdorff) * 100.0
        let chamferSimilarity = (1.0 - normalizedChamfer) * 100.0
        
        // Print results
        print("Hausdorff Distance: \(hausdorffDistance), Similarity: \(hausdorffSimilarity)%")
        print("Chamfer Distance: \(chamferDistance), Similarity: \(chamferSimilarity)%")
        
        // Overall similarity (average of both metrics)
        let overallSimilarity = (hausdorffSimilarity + chamferSimilarity) / 2.0
        print("Overall Similarity: \(overallSimilarity)%")
    }
    
    static func calculateSimilarity(savedPlyFileURL: URL, currentPlyFileString: String) -> Float? {
        // Parse PLY files
        guard let savedPlyFileData = try? Data(contentsOf: savedPlyFileURL),
              let savedPlyFileVertices = PointCloudHelper.parsePLYVertices(data: savedPlyFileData),
        let currentPlyFileVertices = PointCloudHelper.parsePLYVertices(data: currentPlyFileString) else { return nil }
        
        // Compute similarity metrics
        let hausdorffDistance1 = computeHausdorffDistance(vertices1: savedPlyFileVertices, vertices2: currentPlyFileVertices)
        let hausdorffDistance2 = computeHausdorffDistance(vertices1: currentPlyFileVertices, vertices2: savedPlyFileVertices)
        let hausdorffDistance = max(hausdorffDistance1, hausdorffDistance2)
        let chamferDistance = computeChamferDistance(vertices1: savedPlyFileVertices, vertices2: currentPlyFileVertices)
        
        // Normalize distances
        let normalizedHausdorff = normalizeDistance(hausdorffDistance)
        let normalizedChamfer = normalizeDistance(chamferDistance)
        
        // Convert to similarity percentage
        let hausdorffSimilarity = (1.0 - normalizedHausdorff) * 100.0
        let chamferSimilarity = (1.0 - normalizedChamfer) * 100.0
        
        // Print results
        print("Hausdorff Distance: \(hausdorffDistance), Similarity: \(hausdorffSimilarity)%")
        print("Chamfer Distance: \(chamferDistance), Similarity: \(chamferSimilarity)%")
        
        // Overall similarity (average of both metrics)
        let overallSimilarity = (hausdorffSimilarity + chamferSimilarity) / 2.0
        print("Overall Similarity: \(overallSimilarity)%")
        
        return overallSimilarity
    }
}
