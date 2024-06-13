//
//  ARMeshGeometry+Ext.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/13.
//

import Foundation
import ARKit

// Ref: https://developer.apple.com/documentation/arkit/armeshgeometry/
extension ARMeshGeometry {
    func vertex(at index: UInt32) -> SIMD3<Float> {
        let vertexPointer = vertices.buffer.contents().advanced(by: vertices.offset + (vertices.stride * Int(index)))
        let vertex = vertexPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
        return vertex
    }
    
    func vertexIndicesOf(faceWithIndex index: Int) -> [Int] {
        let indicesPerFace = faces.indexCountPerPrimitive
        let facesPointer = faces.buffer.contents()
        var vertexIndices = [Int]()
        for offset in 0..<indicesPerFace {
            let vertexIndexAddress = facesPointer.advanced(by: (index * indicesPerFace + offset) * MemoryLayout<UInt32>.size)
            vertexIndices.append(Int(vertexIndexAddress.assumingMemoryBound(to: UInt32.self).pointee))
        }
        return vertexIndices
    }
}
