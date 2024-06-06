//
//  AppViewModel.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/01.
//

import UIKit

class AppViewModel: ObservableObject {
    // Data
    var capturedPlyFileURLs: [URL] = []
    var capturedImageURLs: [URL] = []
    var currentTimestamp: String?
    var pointCloudData: [(position: SIMD3<Float>, color: UIColor)] = []
    
    // Temporary variable
    var showPointCloudTemp = true
    var showMeshTemp = false
}
