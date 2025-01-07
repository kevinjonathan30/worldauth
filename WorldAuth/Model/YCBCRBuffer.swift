//
//  YCBCRBuffer.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/01/07.
//

import ARKit

final class YCBCRBuffer {
    
    let size: Size
    
    private let pixelBuffer: CVPixelBuffer
    private let yPlane: UnsafeMutableRawPointer
    private let cbCrPlane: UnsafeMutableRawPointer
    private let ySize: Size
    private let cbCrSize: Size
    
    init?(pixelBuffer: CVPixelBuffer) {
        self.pixelBuffer = pixelBuffer
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        
        guard let yPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0),
              let cbCrPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1) else {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            return nil
        }
        
        self.yPlane = yPlane
        self.cbCrPlane = cbCrPlane
        
        size = .init(width: CVPixelBufferGetWidth(pixelBuffer),
                     height: CVPixelBufferGetHeight(pixelBuffer))
        
        ySize = .init(width: CVPixelBufferGetWidthOfPlane(pixelBuffer, 0),
                      height: CVPixelBufferGetHeightOfPlane(pixelBuffer, 0))
        
        cbCrSize = .init(width: CVPixelBufferGetWidthOfPlane(pixelBuffer, 1),
                         height: CVPixelBufferGetHeightOfPlane(pixelBuffer, 1))
    }
    
    func color(posX: Int, posY: Int) -> simd_float4 {
        let yIndex = posY * CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0) + posX
        let uvIndex = posY / 2 * CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1) + posX / 2 * 2
        
        let yValue = yPlane.advanced(by: yIndex)
            .assumingMemoryBound(to: UInt8.self).pointee
        
        let cbValue = cbCrPlane.advanced(by: uvIndex)
            .assumingMemoryBound(to: UInt8.self).pointee
        
        let crValue = cbCrPlane.advanced(by: uvIndex + 1)
            .assumingMemoryBound(to: UInt8.self).pointee
        
        let posY = Float(yValue) - 16
        let cBlue = Float(cbValue) - 128
        let cRed = Float(crValue) - 128
        
        let red = 1.164 * posY + 1.596 * cRed
        let green = 1.164 * posY - 0.392 * cBlue - 0.813 * cRed
        let blue = 1.164 * posY + 2.017 * cBlue
        
        return simd_float4(max(0, min(255, red)) / 255.0,
                           max(0, min(255, green)) / 255.0,
                           max(0, min(255, blue)) / 255.0, 1.0)
    }
    
    deinit {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
    }
}
