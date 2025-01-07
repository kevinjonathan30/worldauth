//
//  Size.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/01/07.
//

import ARKit

struct Size {
    let width: Int
    let height: Int
    
    var asFloat: simd_float2 {
        simd_float2(Float(width), Float(height))
    }
}
