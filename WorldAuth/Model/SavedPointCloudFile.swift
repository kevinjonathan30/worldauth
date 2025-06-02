//
//  SavedPointCloudFile.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/06/02.
//

import Foundation

// Struct to represent saved point cloud files
struct SavedPointCloudFile: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: URL?
    let pointCount: Int?
    let dateCreated: Date?
    let fileSize: String?
    
    init(name: String, url: URL? = nil, pointCount: Int? = nil, dateCreated: Date? = nil, fileSize: String? = nil) {
        self.name = name
        self.url = url
        self.pointCount = pointCount
        self.dateCreated = dateCreated
        self.fileSize = fileSize
    }
}
