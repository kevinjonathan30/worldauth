//
//  WorldAuthCoreML.swift
//  WorldAuthCoreML
//
//  Created by Kevin Jonathan on 2025/05/13.
//

import CoreML
import Foundation

public struct WorldAuthCoreML {

    public static func runInference(source: String, target: String, method: String = "ICP") -> MLMultiArray? {
        switch method {
        case "ICP":
            return nil
        case "FGR":
            return nil
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
    static private func loadDeepGMRTorchScript() -> TorchModule? {
        if let filePath = Bundle.main.path(forResource: "deepgmr", ofType: "pt"),
           let module = TorchModule(fileAtPath: filePath) {
            return module
        } else {
            print("Error loading TorchModule")
            return nil
        }
    }

    static private func runDeepGMRInference(source: String, target: String, threshold: Double) -> MLMultiArray? {
        guard let sourceArray = createMLMultiArray(from: source),
              let targetArray = createMLMultiArray(from: target) else { return nil }

        guard let sourcePoints = mlMultiArrayToFloatArray(sourceArray),
              let targetPoints = mlMultiArrayToFloatArray(targetArray) else { return nil }

        let numPoints1 = Int32(sourcePoints.count / 3) // Assuming 3 coordinates per point
        let numPoints2 = Int32(targetPoints.count / 3)

        guard let model = loadDeepGMRTorchScript() else { return nil }

        let transformationMatrix = sourcePoints.withUnsafeBufferPointer { sourceBuffer in
            targetPoints.withUnsafeBufferPointer { targetBuffer in
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

        guard let tMatrix = convertToMatrix4x4(array: matrix) else {
            print("Error converting transformation matrix to 4x4")
            return nil
        }

        print("Transformation Matrix:", tMatrix)
        return tMatrix
    }

    static private func convertToMatrix4x4(array: [NSNumber]) -> MLMultiArray? {
        do {
            // Initialize an MLMultiArray with shape (4, 4) and data type Double
            let matrix = try MLMultiArray(shape: [4, 4], dataType: .double)

            // Populate the MLMultiArray
            for i in 0..<4 {
                for j in 0..<4 {
                    let index = i * 4 + j
                    if index < array.count {
                        matrix[[NSNumber(value: i), NSNumber(value: j)]] = array[index]
                    } else {
                        matrix[[NSNumber(value: i), NSNumber(value: j)]] = 0.0
                    }
                }
            }
            return matrix
        } catch {
            print("Error creating MLMultiArray: \(error)")
            return nil
        }
    }
}


// MARK: - Helper Functions
public extension WorldAuthCoreML {

    static private func createMLMultiArray(from string: String) -> MLMultiArray? {
        let lines = string.split(separator: "\n")
        let points: [[Float]] = lines.compactMap { line in
            let numbers = line.split(separator: " ").compactMap { Float($0) }
            return numbers.isEmpty ? nil : numbers
        }

        guard !points.isEmpty else { return nil }

        let rowCount = points.count
        let colCount = points[0].count

        do {
            let shape: [NSNumber] = [1, rowCount as NSNumber, colCount as NSNumber]
            let mlArray = try MLMultiArray(shape: shape, dataType: .float32)

            for (index, value) in points.flatMap({ $0 }).enumerated() {
                mlArray[index] = NSNumber(value: value)
            }

            return mlArray
        } catch {
            print("Error creating MLMultiArray: \(error)")
            return nil
        }
    }

    static private func mlMultiArrayToFloatArray(_ multiArray: MLMultiArray) -> [Float]? {
        guard multiArray.dataType == .float32 else {
            print("MLMultiArray data type must be Float32")
            return nil
        }

        // Safely create a buffer pointing to the MLMultiArray's data
        let count = multiArray.count
        let pointer = multiArray.dataPointer.bindMemory(to: Float.self, capacity: count)
        let buffer = UnsafeBufferPointer(start: pointer, count: count)

        // Convert the buffer into an array
        return Array(buffer)
    }
}
