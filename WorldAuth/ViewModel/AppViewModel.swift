//
//  AppViewModel.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/01.
//

import UIKit

class AppViewModel: ObservableObject {
    @Published var capturedPlyFileURLs: [URL] = []
    @Published var capturedImageURLs: [URL] = []
    
    @Published var pointCloudData: [(position: SIMD3<Float>, color: UIColor)] = []
    @Published var isTakingPointCloud = false
    @Published var isScreenBlack = false
    @Published var currentTimestamp: String?

    var showPointCloudTemp = true
    var showMeshTemp = false
}
