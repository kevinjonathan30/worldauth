//
//  AuthenticationHelper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/03/11.
//

import Foundation
import CoreML
import PythonSupport
import Open3DSupport
import NumPySupport
import PythonKit
import WorldAuthCoreML

struct AuthenticationHelper {
    
    // Initialize Python Environment Once
    static func initializePythonEnvironment() {
        PythonSupport.initialize()
        Open3DSupport.sitePackagesURL.insertPythonPath()
        NumPySupport.sitePackagesURL.insertPythonPath()
    }
    
    // Singleton for Python Modules
    struct PythonModules {
        static let o3d = Python.import("open3d")
        static let np = Python.import("numpy")
        static let os = Python.import("os")
        static let sys = Python.import("sys")
    }
    
    static func runInference(source: String, target: String) -> Double {
        switch RemoteConfigProvider.shared.authenticationMethod() {
        case "ICP":
            return runICPInference(source: source, target: target, isFgr: false, threshold: 0.35)
        case "FGR":
            return runICPInference(source: source, target: target, isFgr: true, threshold: 0.32)
        case "PNLK":
            return runPNLKInference(source: source, target: target, threshold: 0.345)
        case "FMR":
            return runFMRInference(source: source, target: target, threshold: 0.35)
        case "DGMR":
            return runDeepGMRInference(source: source, target: target, threshold: 0.47)
        default:
            return 0.0
        }
    }
}

// MARK: - Registration Evaluation
extension AuthenticationHelper {
    static private func evaluateRegistration(source: MLMultiArray, target: MLMultiArray, tMatrix: MLMultiArray, threshold: Double) -> Double {
        let o3d = PythonModules.o3d
        let np = PythonModules.np
        
        let sourceNp = mlMultiArrayToNumPy(source)[0]
        let targetNp = mlMultiArrayToNumPy(target)[0]
        let t21Np = mlMultiArrayToNumPy(tMatrix)
        
        let pcd1 = o3d.geometry.PointCloud()
        let pcd2 = o3d.geometry.PointCloud()
        
        pcd1.points = o3d.utility.Vector3dVector(sourceNp)
        pcd2.points = o3d.utility.Vector3dVector(targetNp)
        
        let pcd1Transformed = o3d.geometry.PointCloud()
        pcd1Transformed.points = o3d.utility.Vector3dVector(np.asarray(pcd1.points))
        
        let transformation = np.array(t21Np).reshape(4, 4)
        
        // Apply transformation using the copied point cloud
        pcd1Transformed.transform(transformation)
        
        // Evaluate registration between target and transformed source
        let evaluation = o3d.pipelines.registration.evaluate_registration(pcd2, pcd1Transformed, threshold)
        print(Double(evaluation.fitness) ?? 0)
        return Double(evaluation.fitness) ?? 0
    }
}

// MARK: - ICP & FGR
extension AuthenticationHelper {
    static private func runICPInference(source: String, target: String, isFgr: Bool, threshold: Double) -> Double {
        let o3d = PythonModules.o3d
        
        guard let source = createMLMultiArray(from: source),
              let target = createMLMultiArray(from: target) else { return 0 }
        
        let sourceNp = mlMultiArrayToNumPy(source)[0]
        let targetNp = mlMultiArrayToNumPy(target)[0]
        
        let voxelSize = 0.1
        
        let pcd1 = o3d.geometry.PointCloud()
        let pcd2 = o3d.geometry.PointCloud()
        
        pcd1.points = o3d.utility.Vector3dVector(sourceNp)
        pcd2.points = o3d.utility.Vector3dVector(targetNp)
        
        let roSource = removeOutlier(cloud: pcd1)
        let roTarget = removeOutlier(cloud: pcd2)
        
        let preparedDataset = prepareDataset(voxelSize: voxelSize, source: roSource, target: roTarget)
        
        let initialResult = performInitialAlignment(voxelSize: voxelSize, preparedDataset: preparedDataset, isFgr: isFgr)
        let transInit = initialResult.transformation
        
        // Apply point-to-plane ICP
        let regP2l = o3d.pipelines.registration.TransformationEstimationPointToPlane()
        let regP2lResult = o3d.pipelines.registration.registration_icp(preparedDataset.0, preparedDataset.1, threshold, transInit, regP2l)
        
        print(Double(regP2lResult.fitness) ?? 0)
        
        return Double(regP2lResult.fitness) ?? 0
    }
    
    static private func removeOutlier(cloud: PythonObject) -> PythonObject {
        let result = cloud.remove_statistical_outlier(nb_neighbors: 20, std_ratio: 2.0)
        return result[0]
    }
    
    static private func prepareDataset(voxelSize: Double, source: PythonObject, target: PythonObject) -> (PythonObject, PythonObject, PythonObject, PythonObject) {
        let sourceResult = preprocessPointCloud(pcd: source, voxelSize: voxelSize)
        let targetResult = preprocessPointCloud(pcd: target, voxelSize: voxelSize)
        
        return (sourceResult.0, targetResult.0, sourceResult.1, targetResult.1)
    }
    
    static private func preprocessPointCloud(pcd: PythonObject, voxelSize: Double) -> (PythonObject, PythonObject) {
        let o3d = PythonModules.o3d
        let pcdDown = pcd.voxel_down_sample(voxelSize)
        
        let radiusNormal = voxelSize * 2
        pcdDown.estimate_normals(o3d.geometry.KDTreeSearchParamHybrid(radius: radiusNormal, max_nn: 30))
        
        let radiusFeature = voxelSize * 5
        let pcdFpfh = o3d.pipelines.registration.compute_fpfh_feature(pcdDown, o3d.geometry.KDTreeSearchParamHybrid(radius: radiusFeature, max_nn: 100))
        
        return (pcdDown, pcdFpfh)
    }
    
    static private func performInitialAlignment(voxelSize: Double, preparedDataset: (PythonObject, PythonObject, PythonObject, PythonObject), isFgr: Bool) -> PythonObject {
        let o3d = PythonModules.o3d
        
        if isFgr { // FGR
            let distanceThreshold = voxelSize * 1.5
            let result = o3d.pipelines.registration.registration_fgr_based_on_feature_matching(
                preparedDataset.0,
                preparedDataset.1,
                preparedDataset.2,
                preparedDataset.3,
                o3d.pipelines.registration.FastGlobalRegistrationOption(maximum_correspondence_distance: distanceThreshold)
            )
            
            return result
        } else { // RANSAC
            let distanceThreshold = voxelSize * 1.5
            
            let checkers = [o3d.pipelines.registration.CorrespondenceCheckerBasedOnEdgeLength(0.9),
                            o3d.pipelines.registration.CorrespondenceCheckerBasedOnDistance(distanceThreshold)]
            let criteria = o3d.pipelines.registration.RANSACConvergenceCriteria(10000, 500)
            let reg = o3d.pipelines.registration.TransformationEstimationPointToPoint(false)
            
            let result = o3d.pipelines.registration.registration_ransac_based_on_feature_matching(
                preparedDataset.0,
                preparedDataset.1,
                preparedDataset.2,
                preparedDataset.3,
                mutual_filter: true,
                max_correspondence_distance: distanceThreshold,
                estimation_method: reg,
                ransac_n: 3,
                checkers: checkers,
                criteria: criteria
            )
            
            return result
        }
    }
}

// MARK: - PNLK

extension AuthenticationHelper {
    static func runPNLKInference(source: String, target: String, threshold: Double) -> Double {
        let sourceData = Data(source.utf8)
        let targetData = Data(target.utf8)
        if let result = authenticateTwoPointCloudsSync(sourceData, targetData) {
            return result.fitness ?? 0
        }
        return 0
    }
}

// MARK: - FMR

extension AuthenticationHelper {
    static func runFMRInference(source: String, target: String, threshold: Double) -> Double {
        let sourceData = Data(source.utf8)
        let targetData = Data(target.utf8)
        if let result = authenticateTwoPointCloudsSync(sourceData, targetData) {
            return result.fitness ?? 0
        }
        return 0
    }
}

// MARK: - DeepGMR with TorchScript (LibTorch)

extension AuthenticationHelper {
    static private func runDeepGMRInference(source: String, target: String, threshold: Double) -> Double {
        guard let sourceTemp = createMLMultiArray(from: source),
              let targetTemp = createMLMultiArray(from: target) else { return 0 }
        
        guard let tMatrix = WorldAuthCoreML.runInference(source: source, target: target, method: "DGMR") else { return 0 }
        
        return evaluateRegistration(source: sourceTemp, target: targetTemp, tMatrix: tMatrix, threshold: threshold)
    }
}

// MARK: - Helper Functions

extension AuthenticationHelper {
    
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
    
    static private func mlMultiArrayToNumPy(_ multiArray: MLMultiArray) -> PythonObject {
        let np = PythonModules.np
        let shape = multiArray.shape.map { $0.intValue }
        
        var arrayData = [Double](repeating: 0.0, count: multiArray.count)
        for i in 0..<multiArray.count {
            arrayData[i] = multiArray[i].doubleValue
        }
        
        let npArray = np.array(arrayData).reshape(shape)
        
        return npArray
    }
    
    static private func numpyToMLMultiArray(_ numpyArray: PythonObject) -> MLMultiArray? {
        let np = PythonModules.np
        
        guard Bool(np.isinstance(numpyArray, np.ndarray)) == true else {
            print("Input is not a NumPy array.")
            return nil
        }
        
        let shapeTuple = numpyArray.shape
        let shape = (0..<(Int(Python.len(shapeTuple)) ?? 0)).map { Int(shapeTuple[$0])! }
        let flattened = numpyArray.flatten().astype(np.float64)
        
        let swiftArray: [Double] = Array(flattened)!
        
        guard let mlArray = try? MLMultiArray(shape: shape.map { NSNumber(value: $0) }, dataType: .double) else {
            print("Failed to initialize MLMultiArray.")
            return nil
        }
        
        for i in 0..<mlArray.count {
            mlArray[i] = NSNumber(value: swiftArray[i])
        }
        
        return mlArray
    }
    
    
    static private func transformPoints(pts2: PythonObject, t21: PythonObject) -> PythonObject {
        let R = t21.slice(0, 3, 0, 3).T
        let t = t21.slice(0, 3, 3)
        
        return (pts2.dot(R)) + t
    }
    
    static private func parsePLYString(_ plyString: String) -> [Float]? {
        var points: [Float] = []
        let lines = plyString.split(separator: "\n")
        var isHeader = true
        
        for line in lines {
            if isHeader {
                if line.starts(with: "end_header") {
                    isHeader = false
                }
                continue
            }
            
            let components = line.split(separator: " ").compactMap { Float($0) }
            if components.count >= 3 { // Ensure we have at least x, y, z
                points.append(contentsOf: components.prefix(3)) // Add x, y, z only
            }
        }
        return points.isEmpty ? nil : points
    }
    
    static private func mlMultiArrayToFloatArray(_ multiArray: MLMultiArray) -> [Float]? {
        guard multiArray.dataType == .float32 else {
            print("MLMultiArray data type must be Float32")
            return nil
        }
        
        let count = multiArray.count
        var floatArray = [Float](repeating: 0, count: count)
        multiArray.dataPointer.copyMemory(from: &floatArray, byteCount: count * MemoryLayout<Float>.size)
        return floatArray
    }
    
    static func authenticateTwoPointCloudsSync(_ sourceFile: Data, _ targetFile: Data) -> AuthenticationResult? {
        var result: AuthenticationResult?
        let semaphore = DispatchSemaphore(value: 0)
        
        NetworkHelper.authenticateTwoPointClouds(sourceFile, targetFile) { response, error in
            if error == nil {
                result = response
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
}
