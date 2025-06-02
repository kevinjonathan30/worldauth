//
//  PointCloudHelper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/06/02.
//

import Foundation

struct PointCloudHelper {
    static func extractPointCountFromFile(url: URL) -> Int {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            
            // Split the content into lines and filter out empty or invalid lines
            let validLines = content.split(whereSeparator: \.isNewline).filter { line in
                // Check if the line contains valid float data (e.g., "x y z")
                let components = line.split(separator: " ").compactMap { Float($0) }
                return components.count == 3 // Each vertex line should have exactly 3 components
            }
            
            return validLines.count
        } catch {
            print("Error reading file for point count: \(error.localizedDescription)")
        }
        return 0
    }
}
