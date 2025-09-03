//
//  WorldAuthCoreML.swift
//  WorldAuthCoreML
//
//  Created by Kevin Jonathan on 2025/05/13.
//

import CoreML
import Foundation

public struct WorldAuthCoreML {

    public static func runInference(source: String, target: String, method: String = "ICP") -> [NSNumber]? {
        switch method {
        case "PNLK":
            return nil
        case "FMR":
            return nil
        case "DGMR":
            return runDeepGMRInference(source: source, target: target, threshold: 0.49)
        default:
            return nil
        }
    }
}

// MARK: - DeepGMR with TorchScript (LibTorch)

public extension WorldAuthCoreML {
    static private func loadDeepGMRTorchScript() -> DGMRModule? {
        if let filePath = Bundle(identifier: "jp.ac.waseda.cs.WorldAuthCoreML")?.path(forResource: "deepgmr", ofType: "pt"),
           let module = DGMRModule(fileAtPath: filePath) {
            return module
        } else {
            print("Error loading TorchModule")
            return nil
        }
    }

    static private func runDeepGMRInference(source: String, target: String, threshold: Double) -> [NSNumber]? {
        guard var sourcePoints = stringToFloatArray(source),
              var targetPoints = stringToFloatArray(target) else { return nil }

        let numPoints1 = Int32(sourcePoints.count / 3) // Assuming 3 coordinates per point
        let numPoints2 = Int32(targetPoints.count / 3)

        guard let model = loadDeepGMRTorchScript() else { return nil }

        let transformationMatrix = sourcePoints.withUnsafeMutableBufferPointer { sourceBuffer in
            targetPoints.withUnsafeMutableBufferPointer { targetBuffer in
                model.registerPointCloud(
                    points1: sourceBuffer.baseAddress!,
                    numPoints1: numPoints1,
                    points2: targetBuffer.baseAddress!,
                    numPoints2: numPoints2
                )
            }
        }

        guard let matrix = transformationMatrix else {
            print("Failed to get transformation matrix")
            return nil
        }

        print("Transformation Matrix:", matrix)
        return matrix
    }
}


// MARK: - Helper Functions
public extension WorldAuthCoreML {

    static private func stringToFloatArray(_ string: String) -> [Float]? {
        let points: [Float] = string
            .split(separator: "\n")
            .flatMap { line in
                line.split(separator: " ").compactMap { Float($0) }
            }
        
        return points.isEmpty ? nil : points
    }
}
