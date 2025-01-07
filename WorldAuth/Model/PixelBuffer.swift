//
//  PixelBuffer.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/01/07.
//

import ARKit

final class PixelBuffer<T> {
    
    let size: Size
    let bytesPerRow: Int
    
    private let pixelBuffer: CVPixelBuffer
    private let baseAddress: UnsafeMutableRawPointer
    
    init?(pixelBuffer: CVPixelBuffer) {
        self.pixelBuffer = pixelBuffer
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        
        guard let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            return nil
        }
        self.baseAddress = baseAddress
        
        size = .init(width: CVPixelBufferGetWidth(pixelBuffer),
                     height: CVPixelBufferGetHeight(pixelBuffer))
        bytesPerRow =  CVPixelBufferGetBytesPerRow(pixelBuffer)
    }
    
    func value(posX: Int, posY: Int) -> T {
        
        let rowPtr = baseAddress.advanced(by: posY * bytesPerRow)
        return rowPtr.assumingMemoryBound(to: T.self)[posX]
    }
    
    deinit {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
    }
}
