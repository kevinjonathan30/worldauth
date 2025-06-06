//
//  PLYFile.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/01/07.
//

import Foundation
import ARKit

struct PLYFile {
    let pointCloud: PointCloud
    
    func exportToPlyString() async throws -> String {
        let vertices = await pointCloud.vertices
        
        var plyContent = """
            ply
            format ascii 1.0
            element vertex \(vertices.count)
            property float x
            property float y
            property float z
            end_header
            """
        
        for vertex in vertices.values {
            let posX = vertex.position.x
            let posY = vertex.position.y
            let posZ = vertex.position.z
            
            plyContent += "\n\(posX) \(posY) \(posZ)"
        }
        
        return plyContent
    }
    
    enum Error: LocalizedError {
        case cannotExport
    }
    
    private func savePLYFileToDocuments(fileName: String, data: Data) throws -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        try data.write(to: fileURL)
        return fileURL
    }
    
    func exportToLocalFile() async throws -> URL {
        let vertices = await pointCloud.vertices
        
        var plyContent = """
            ply
            format ascii 1.0
            element vertex \(vertices.count)
            property float x
            property float y
            property float z
            property uchar red
            property uchar green
            property uchar blue
            property uchar alpha
            end_header
            """
        
        for vertex in vertices.values {
            let posX = vertex.position.x
            let posY = vertex.position.y
            let posZ = vertex.position.z
            let red = UInt8(vertex.color.x * 255)
            let green = UInt8(vertex.color.y * 255)
            let blue = UInt8(vertex.color.z * 255)
            let alpha = UInt8(vertex.color.w * 255)
            
            plyContent += "\n\(posX) \(posY) \(posZ) \(red) \(green) \(blue) \(alpha)"
        }
        
        guard let data = plyContent.data(using: .ascii) else {
            throw Error.cannotExport
        }
        
        let today = Date.now
        let formatter3 = DateFormatter()
        formatter3.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        
        return try savePLYFileToDocuments(fileName: "exported-\(formatter3.string(from: today)).ply", data: data)
    }
}
