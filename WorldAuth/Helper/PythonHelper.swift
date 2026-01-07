//
//  PythonHelper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/06/02.
//

import Foundation
import CoreML
import PythonSupport
import Open3DSupport
import NumPySupport
import PythonKit

struct PythonHelper {
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
}

// MARK: - Public Functions

extension PythonHelper {
    static func downsampleAndNormalizePointCloudString(pointCloudString: String) -> String? {
        guard let np = convertStringToNumPyXYZ(pointCloudString) else { return nil }
        let o3d = PythonModules.o3d
        let pcd = o3d.geometry.PointCloud()
        
        pcd.points = o3d.utility.Vector3dVector(np)
        
        let pcdDown = preprocessPointCloud(
            pcd: pcd,
            voxelSize: 0.1
        )
        return convertPointCloudToString(pcdDown)
    }
    
    static func evaluateRegistration(
        source: PythonObject,
        target: PythonObject,
        matrix: PythonObject,
        threshold: Double
    ) -> Double {
        let o3d = PythonModules.o3d
        let np = PythonModules.np
        
        let pcd1 = o3d.geometry.PointCloud()
        let pcd2 = o3d.geometry.PointCloud()
        
        pcd1.points = o3d.utility.Vector3dVector(source)
        pcd2.points = o3d.utility.Vector3dVector(target)
        
        let pcd1Transformed = o3d.geometry.PointCloud()
        pcd1Transformed.points = o3d.utility.Vector3dVector(np.asarray(pcd1.points))
        
        // Apply transformation using the copied point cloud
        pcd1Transformed.transform(matrix)
        
        // Evaluate registration between target and transformed source
        let evaluation = o3d.pipelines.registration.evaluate_registration(
            pcd2,
            pcd1Transformed,
            threshold
        )

        return Double(evaluation.fitness) ?? 0
    }
}

// MARK: - ICP & FGR

extension PythonHelper {
    static func runICPInference(
        source: String,
        target: String,
        isFgr: Bool,
        threshold: Double
    ) -> Double {
        let o3d = PythonModules.o3d
        
        guard let sourceNp = convertStringToNumPyXYZNormals(source),
              let targetNp = convertStringToNumPyXYZNormals(target) else { return 0 }
        
        let voxelSize = 0.1
        
        let pcd1 = o3d.geometry.PointCloud()
        let pcd2 = o3d.geometry.PointCloud()
        
        pcd1.points = o3d.utility.Vector3dVector(sourceNp.0)
        pcd1.normals = o3d.utility.Vector3dVector(sourceNp.1)
        pcd2.points = o3d.utility.Vector3dVector(targetNp.0)
        pcd2.normals = o3d.utility.Vector3dVector(targetNp.1)
        
        let preparedDataset = prepareDataset(
            voxelSize: voxelSize,
            source: pcd1,
            target: pcd2
        )
        
        let initialResult = performInitialAlignment(
            voxelSize: voxelSize,
            preparedDataset: preparedDataset,
            isFgr: isFgr
        )
        let transInit = initialResult.transformation
        
        // Apply point-to-plane ICP
        let regP2l = o3d.pipelines.registration.TransformationEstimationPointToPlane()
        let regP2lResult = o3d.pipelines.registration.registration_icp(
            preparedDataset.0,
            preparedDataset.1,
            threshold,
            transInit,
            regP2l
        )
        
        return Double(regP2lResult.fitness) ?? 0
    }
    
    static private func removeOutlier(cloud: PythonObject) -> PythonObject {
        let result = cloud.remove_statistical_outlier(
            nb_neighbors: 20,
            std_ratio: 2.0
        )
        return result[0]
    }
    
    static private func prepareDataset(
        voxelSize: Double,
        source: PythonObject,
        target: PythonObject
    ) -> (PythonObject, PythonObject, PythonObject, PythonObject) {
        let pcdFpfh1 = computeFPFHFeature(pcd: source, voxelSize: voxelSize)
        let pcdFpfh2 = computeFPFHFeature(pcd: target, voxelSize: voxelSize)
        
        return (source, target, pcdFpfh1, pcdFpfh2)
    }
    
    static private func preprocessPointCloud(
        pcd: PythonObject,
        voxelSize: Double
    ) -> (PythonObject) {
        let o3d = PythonModules.o3d
        let pcdNoOutlier = removeOutlier(cloud: pcd)
        let pcdDown = pcdNoOutlier.voxel_down_sample(voxelSize)
        
        let radiusNormal = voxelSize * 2
        pcdDown.estimate_normals(
            o3d.geometry.KDTreeSearchParamHybrid(
                radius: radiusNormal,
                max_nn: 30
            )
        )
        pcdDown.orient_normals_consistent_tangent_plane(100)
        
        return pcdDown
    }
    
    static private func computeFPFHFeature(
        pcd: PythonObject,
        voxelSize: Double
    ) -> PythonObject {
        let o3d = PythonModules.o3d
        let radiusFeature = voxelSize * 5
        let pcdFpfh = o3d.pipelines.registration.compute_fpfh_feature(
            pcd,
            o3d.geometry.KDTreeSearchParamHybrid(radius: radiusFeature, max_nn: 100)
        )
        
        return pcdFpfh
    }
    
    static private func performInitialAlignment(
        voxelSize: Double,
        preparedDataset: (PythonObject, PythonObject, PythonObject, PythonObject),
        isFgr: Bool
    ) -> PythonObject {
        let o3d = PythonModules.o3d
        
        if isFgr { // FGR
            let distanceThreshold = voxelSize * 1.1
            
            let option = o3d.pipelines.registration.FastGlobalRegistrationOption(
                maximum_correspondence_distance: distanceThreshold,
                iteration_number: 512,
                maximum_tuple_count: 1534,
                tuple_scale: 0.98,
                use_absolute_scale: false,
                decrease_mu: true,
                tuple_test: true,
                division_factor: 1.01
            )
            
            let result = o3d.pipelines.registration.registration_fgr_based_on_feature_matching(
                preparedDataset.0,
                preparedDataset.1,
                preparedDataset.2,
                preparedDataset.3,
                option
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

// MARK: - Helper Functions

extension PythonHelper {
    static func convertStringToNumPyXYZ(_ string: String) -> PythonObject? {
        let np = PythonModules.np

        var flat: [Float] = []

        for line in string.split(whereSeparator: \.isNewline) {
            let parts = line.split { $0 == " " || $0 == "\t" }
            guard parts.count >= 3,
                  let x = Float(parts[0]),
                  let y = Float(parts[1]),
                  let z = Float(parts[2]) else { continue }
            flat.append(x)
            flat.append(y)
            flat.append(z)
        }

        let n = flat.count / 3
        guard n > 0 else { return nil }

        // Swift [Float] -> Python list -> NumPy float32 array shaped (N, 3)
        let pyList = PythonObject(flat.map { PythonObject($0) })
        let arr = np.array(pyList, dtype: np.float32).reshape([n, 3])
        return arr
    }
    
    static func convertStringToNumPyXYZNormals(_ string: String) -> (PythonObject, PythonObject)? {
        let np = PythonModules.np

        var xyzFlat: [Float] = []
        var normalsFlat: [Float] = []

        for line in string.split(whereSeparator: \.isNewline) {
            let parts = line.split { $0 == " " || $0 == "\t" }
            guard parts.count >= 6,
                  let x = Float(parts[0]),
                  let y = Float(parts[1]),
                  let z = Float(parts[2]),
                  let nx = Float(parts[3]),
                  let ny = Float(parts[4]),
                  let nz = Float(parts[5]) else { continue }

            xyzFlat.append(x)
            xyzFlat.append(y)
            xyzFlat.append(z)

            normalsFlat.append(nx)
            normalsFlat.append(ny)
            normalsFlat.append(nz)
        }

        let n = xyzFlat.count / 3
        guard n > 0 else { return nil }

        // Convert Swift [Float] -> Python list -> NumPy array
        let xyzPyList = PythonObject(xyzFlat.map { PythonObject($0) })
        let normalsPyList = PythonObject(normalsFlat.map { PythonObject($0) })

        let xyzArr = np.array(xyzPyList, dtype: np.float32).reshape([n, 3])
        let normalsArr = np.array(normalsPyList, dtype: np.float32).reshape([n, 3])

        return (xyzArr, normalsArr)
    }

    
    static func convertToNumPyMatrix4x4(array: [NSNumber]) -> PythonObject? {
        let np = PythonModules.np
        
        guard array.count == 16 else {
            return nil
        }
        
        let values = array.map { $0.doubleValue }
        let pyList = PythonObject(values.map { PythonObject($0) })
        
        let npArray = np.array(pyList, dtype: np.float64).reshape([4, 4])
        return npArray
    }
    
    static func convertPointCloudToString(_ pcd: PythonObject) -> String {
        let points = Array(pcd.points)
        let normals = Array(pcd.normals)
        
        let numPoints = points.count
        var plyString = """
            ply
            format ascii 1.0
            element vertex \(numPoints)
            property float x
            property float y
            property float z
            property float nx
            property float ny
            property float nz
            end_header
            """
        
        for i in 0..<numPoints {
            let x = points[i][0]
            let y = points[i][1]
            let z = points[i][2]
            let nx = normals[i][0]
            let ny = normals[i][1]
            let nz = normals[i][2]
            plyString += "\n\(x) \(y) \(z) \(nx) \(ny) \(nz)"
        }
        
        return plyString
    }
}
