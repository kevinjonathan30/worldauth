//
//  WorldAuthCore.swift
//  WorldAuthCore
//
//  Created by Kevin Jonathan on 2025/05/12.
//

import CoreML
import Foundation

public struct WorldAuthCore {

//    public static func runInference(source: String, target: String, method: String = "ICP") -> MLMultiArray? {
//        switch method {
//        case "ICP":
//            return nil
//        case "FGR":
//            return nil
//        case "PNLK":
//            return nil
//        case "FMR":
//            return nil
//        case "DGMR":
//            return runDeepGMRInference(source: source, target: target, threshold: 0.49)
//        default:
//            return nil
//        }
//    }
}

//// MARK: - DeepGMR with TorchScript (LibTorch)
//
//public extension WorldAuthCore {
//    static private func loadDeepGMRTorchScript() -> TorchModule? {
//        if let filePath = Bundle.main.path(forResource: "deepgmr", ofType: "pt"),
//           let module = TorchModule(fileAtPath: filePath) {
//            return module
//        } else {
//            print("Error loading TorchModule")
//            return nil
//        }
//    }
//
//    static private func runDeepGMRInference(source: String, target: String, threshold: Double) -> MLMultiArray? {
//        guard let sourceArray = createMLMultiArray(from: source),
//              let targetArray = createMLMultiArray(from: target) else { return nil }
//
//        guard let sourcePoints = mlMultiArrayToFloatArray(sourceArray),
//              let targetPoints = mlMultiArrayToFloatArray(targetArray) else { return nil }
//
//        // Allocate memory for the source and target points
//        let sourcePointer = UnsafeMutablePointer<Float>.allocate(capacity: sourcePoints.count)
//        let targetPointer = UnsafeMutablePointer<Float>.allocate(capacity: targetPoints.count)
//
//        // Copy the data into the allocated memory
//        sourcePointer.initialize(from: sourcePoints, count: sourcePoints.count)
//        targetPointer.initialize(from: targetPoints, count: targetPoints.count)
//
//        let numPoints1 = Int32(sourcePoints.count / 3) // Assuming 3 coordinates per point
//        let numPoints2 = Int32(targetPoints.count / 3)
//
//        guard let model = loadDeepGMRTorchScript() else {
//            sourcePointer.deallocate()
//            targetPointer.deallocate()
//            return nil
//        }
//
//        guard let transformationMatrix = model.registerPointCloud(
//            points1: sourcePointer,
//            numPoints1: numPoints1,
//            points2: targetPointer,
//            numPoints2: numPoints2
//        ) else {
//            print("Failed to get transformation matrix")
//            sourcePointer.deallocate()
//            targetPointer.deallocate()
//            return nil
//        }
//
//        // Deallocate pointers
//        sourcePointer.deallocate()
//        targetPointer.deallocate()
//
//        guard let tMatrix = convertToMatrix4x4(array: transformationMatrix) else {
//            print("Error converting transformation matrix to 4x4")
//            return nil
//        }
//
//        print("Transformation Matrix:", tMatrix)
//        return tMatrix
//    }
//
//    static private func convertToMatrix4x4(array: [NSNumber]) -> MLMultiArray? {
//        do {
//            // Initialize an MLMultiArray with shape (4, 4) and data type Double
//            let matrix = try MLMultiArray(shape: [4, 4], dataType: .double)
//
//            // Populate the MLMultiArray
//            for i in 0..<4 {
//                for j in 0..<4 {
//                    let index = i * 4 + j
//                    if index < array.count {
//                        matrix[[NSNumber(value: i), NSNumber(value: j)]] = array[index]
//                    } else {
//                        matrix[[NSNumber(value: i), NSNumber(value: j)]] = 0.0
//                    }
//                }
//            }
//            return matrix
//        } catch {
//            print("Error creating MLMultiArray: \(error)")
//            return nil
//        }
//    }
//}
//
//
//// MARK: - Helper Functions
//public extension WorldAuthCore {
//
//    static private func createMLMultiArray(from string: String) -> MLMultiArray? {
//        let lines = string.split(separator: "\n")
//        let points: [[Float]] = lines.compactMap { line in
//            let numbers = line.split(separator: " ").compactMap { Float($0) }
//            return numbers.isEmpty ? nil : numbers
//        }
//
//        guard !points.isEmpty else { return nil }
//
//        let rowCount = points.count
//        let colCount = points[0].count
//
//        do {
//            let shape: [NSNumber] = [1, rowCount as NSNumber, colCount as NSNumber]
//            let mlArray = try MLMultiArray(shape: shape, dataType: .float32)
//
//            for (index, value) in points.flatMap({ $0 }).enumerated() {
//                mlArray[index] = NSNumber(value: value)
//            }
//
//            return mlArray
//        } catch {
//            print("Error creating MLMultiArray: \(error)")
//            return nil
//        }
//    }
//
//    //    static private func mlMultiArrayToNumPy(_ multiArray: MLMultiArray) -> PythonObject {
//    //        let np = PythonModules.np
//    //        let shape = multiArray.shape.map { $0.intValue }
//    //
//    //        var arrayData = [Double](repeating: 0.0, count: multiArray.count)
//    //        for i in 0..<multiArray.count {
//    //            arrayData[i] = multiArray[i].doubleValue
//    //        }
//    //
//    //        let npArray = np.array(arrayData).reshape(shape)
//    //
//    //        return npArray
//    //    }
//    //
//    //    static private func numpyToMLMultiArray(_ numpyArray: PythonObject) -> MLMultiArray? {
//    //        let np = PythonModules.np
//    //
//    //        guard Bool(np.isinstance(numpyArray, np.ndarray)) == true else {
//    //            print("Input is not a NumPy array.")
//    //            return nil
//    //        }
//    //
//    //        let shapeTuple = numpyArray.shape
//    //        let shape = (0..<(Int(Python.len(shapeTuple)) ?? 0)).map { Int(shapeTuple[$0])! }
//    //        let flattened = numpyArray.flatten().astype(np.float64)
//    //
//    //        let swiftArray: [Double] = Array(flattened)!
//    //
//    //        guard let mlArray = try? MLMultiArray(shape: shape.map { NSNumber(value: $0) }, dataType: .double) else {
//    //            print("Failed to initialize MLMultiArray.")
//    //            return nil
//    //        }
//    //
//    //        for i in 0..<mlArray.count {
//    //            mlArray[i] = NSNumber(value: swiftArray[i])
//    //        }
//    //
//    //        return mlArray
//    //    }
//    //
//    //
//    //    static private func transformPoints(pts2: PythonObject, t21: PythonObject) -> PythonObject {
//    //        let R = t21.slice(0, 3, 0, 3).T
//    //        let t = t21.slice(0, 3, 3)
//    //
//    //        return (pts2.dot(R)) + t
//    //    }
//
//    static private func parsePLYString(_ plyString: String) -> [Float]? {
//        var points: [Float] = []
//        let lines = plyString.split(separator: "\n")
//        var isHeader = true
//
//        for line in lines {
//            if isHeader {
//                if line.starts(with: "end_header") {
//                    isHeader = false
//                }
//                continue
//            }
//
//            let components = line.split(separator: " ").compactMap { Float($0) }
//            if components.count >= 3 { // Ensure we have at least x, y, z
//                points.append(contentsOf: components.prefix(3)) // Add x, y, z only
//            }
//        }
//        return points.isEmpty ? nil : points
//    }
//
//    static private func mlMultiArrayToFloatArray(_ multiArray: MLMultiArray) -> [Float]? {
//        guard multiArray.dataType == .float32 else {
//            print("MLMultiArray data type must be Float32")
//            return nil
//        }
//
//        let count = multiArray.count
//        var floatArray = [Float](repeating: 0, count: count)
//        multiArray.dataPointer.copyMemory(from: &floatArray, byteCount: count * MemoryLayout<Float>.size)
//        return floatArray
//    }
//}
