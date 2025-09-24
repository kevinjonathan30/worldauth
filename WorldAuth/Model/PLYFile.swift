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
        var lines: [String] = []
        lines.reserveCapacity(vertices.count)
        for vertex in vertices.values {
            let posX = vertex.position.x
            let posY = vertex.position.y
            let posZ = vertex.position.z
            lines.append("\(posX) \(posY) \(posZ)")
        }
        return lines.joined(separator: "\n") + "\n"
    }
    
    func exportToPlyStringColored() async -> String {
        let vertices = await pointCloud.vertices
        var lines: [String] = []
        lines.reserveCapacity(vertices.count + 9)
        lines.append("ply")
        lines.append("format ascii 1.0")
        lines.append("element vertex \(vertices.count)")
        lines.append("property float x")
        lines.append("property float y")
        lines.append("property float z")
        lines.append("property uchar red")
        lines.append("property uchar green")
        lines.append("property uchar blue")
        lines.append("end_header")
        for vertex in vertices.values {
            let posX = vertex.position.x
            let posY = vertex.position.y
            let posZ = vertex.position.z
            let red = UInt8(vertex.color.x * 255)
            let green = UInt8(vertex.color.y * 255)
            let blue = UInt8(vertex.color.z * 255)
            lines.append("\(posX) \(posY) \(posZ) \(red) \(green) \(blue)")
        }
        return lines.joined(separator: "\n")
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

