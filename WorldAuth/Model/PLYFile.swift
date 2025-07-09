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
    
    func exportBothToPlyString() async -> (String, String) {
        let plyString = await exportToPlyString()
        let plyStringColored = await exportToPlyStringColored()
        return (plyString, plyStringColored)
    }
    
    func exportToPlyString() async -> String {
        let vertices = await pointCloud.vertices
        
        var plyContent = ""
        
        for vertex in vertices.values {
            let posX = vertex.position.x
            let posY = vertex.position.y
            let posZ = vertex.position.z
            
            plyContent += "\(posX) \(posY) \(posZ)\n"
        }
        
        return plyContent
    }
    
    func exportToPlyStringColored() async -> String {
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
            end_header
            """
        
        for vertex in vertices.values {
            let posX = vertex.position.x
            let posY = vertex.position.y
            let posZ = vertex.position.z
            let red = UInt8(vertex.color.x * 255)
            let green = UInt8(vertex.color.y * 255)
            let blue = UInt8(vertex.color.z * 255)
            
            plyContent += "\n\(posX) \(posY) \(posZ) \(red) \(green) \(blue)"
        }
        
        return plyContent
    }
}

// MARK: Header Format

//        var plyContent = """
//            ply
//            format ascii 1.0
//            element vertex \(vertices.count)
//            property float x
//            property float y
//            property float z
//            end_header
//            """
