//
//  PointCloud.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/01/07.
//

import ARKit

actor PointCloud {
    
    func process(frame: ARFrame) async {
        guard let depth = (frame.smoothedSceneDepth ?? frame.sceneDepth),
              let depthBuffer = PixelBuffer<Float32>(pixelBuffer: depth.depthMap),
              let confidenceMap = depth.confidenceMap,
              let confidenceBuffer = PixelBuffer<UInt8>(pixelBuffer: confidenceMap),
              let imageBuffer = YCBCRBuffer(pixelBuffer: frame.capturedImage) else { return }
        
        let rotateToARCamera = makeRotateToARCameraMatrix(orientation: .portrait)
        let cameraTransform = frame.camera.viewMatrix(for: .portrait).inverse * rotateToARCamera
        
        for row in 0..<depthBuffer.size.height {
            for col in 0..<depthBuffer.size.width {
                let confidenceRawValue = Int(confidenceBuffer.value(posX: col, posY: row))
                guard let confidence = ARConfidenceLevel(rawValue: confidenceRawValue), confidence == .high else { continue }
                
                let depth = depthBuffer.value(posX: col, posY: row)
                
                if depth < 0.3 || depth > 2 { return }
                
                let normalizedCoord = simd_float2(Float(col) / Float(depthBuffer.size.width),
                                                  Float(row) / Float(depthBuffer.size.height))
                
                let imageSize = imageBuffer.size.asFloat
                let screenPoint = simd_float3(normalizedCoord * imageSize, 1)
                
                let localPoint = simd_inverse(frame.camera.intrinsics) * screenPoint * depth
                
                let worldPoint = cameraTransform * simd_float4(localPoint, 1)
                
                let resultPosition = (worldPoint / worldPoint.w)
                
                let pointPosition = SCNVector3(x: resultPosition.x,
                                               y: resultPosition.y,
                                               z: resultPosition.z)
                
                let key = PointCloud.GridKey(pointPosition)
                
                if vertices[key] == nil {
                    let pixelRow = Int(round(normalizedCoord.y * imageSize.y))
                    let pixelColumn = Int(round(normalizedCoord.x * imageSize.x))
                    let color = imageBuffer.color(posX: pixelColumn, posY: pixelRow)
                    
                    vertices[key] = PointCloud.Vertex(position: pointPosition,
                                                      color: color)
                }
            }
        }
    }
    
    func makeRotateToARCameraMatrix(orientation: UIInterfaceOrientation) -> matrix_float4x4 {
        let flipYZ = matrix_float4x4(
            [1, 0, 0, 0],
            [0, -1, 0, 0],
            [0, 0, -1, 0],
            [0, 0, 0, 1]
        )
        let rotationAngle: Float = switch orientation {
        case .landscapeLeft: .pi
        case .portrait: .pi / 2
        case .portraitUpsideDown: -.pi / 2
        default: 0
        }
        let quaternion = simd_quaternion(rotationAngle, simd_float3(0, 0, 1))
        let rotationMatrix = matrix_float4x4(quaternion)
        
        return flipYZ * rotationMatrix
    }
    
    struct GridKey: Hashable {
        
        static let density: Float = 100
        
        private let id: Int
        
        init(_ position: SCNVector3) {
            var hasher = Hasher()
            for component in [position.x, position.y, position.z] {
                hasher.combine(Int(round(component * Self.density)))
            }
            id = hasher.finalize()
        }
    }
    
    struct Vertex {
        let position: SCNVector3
        let color: simd_float4
    }
    
    private(set) var vertices: [GridKey: Vertex] = [:]
    
    func clear() {
        vertices.removeAll()
    }
}
