//
//  AuthenticationHelper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/03/11.
//

import Foundation
import CoreML
#if os(iOS)
import WorldAuthCoreML
#endif

struct AuthenticationHelper {
    
    static func runInference(source: String, target: String) -> Double {
        var threshold: Double = 0.0
        var authTime: Double = 0.0
        var fitness: Double = 0.0
        let method: String = RemoteConfigProvider.shared.authenticationMethod()
        
        let startTime = Date()
        
        switch method {
        case "ICP":
            threshold = 0.35
            fitness = runICPInference(source: source, target: target, isFgr: false, threshold: threshold)
        case "FGR":
            threshold = 0.1005
            fitness = runICPInference(source: source, target: target, isFgr: true, threshold: threshold)
        case "PNLK":
            threshold = 0.345
            fitness = runPNLKInference(source: source, target: target, threshold: threshold)
        case "FMR":
            threshold = 0.35
            fitness = runFMRInference(source: source, target: target, threshold: threshold)
        case "DGMR":
            threshold = 0.47
            fitness = runDeepGMRInference(source: source, target: target, threshold: threshold)
        default:
            break
        }
        
        let endTime = Date()
        authTime = endTime.timeIntervalSince(startTime)
        
        LoggerHelper.logInfo(
            parameters: [
                .method: method,
                .fitness: fitness,
                .threshold: threshold,
                .authTime: authTime
            ]
        )
        
        return fitness
    }
}

// MARK: - ICP & FGR

extension AuthenticationHelper {
    static private func runICPInference(source: String, target: String, isFgr: Bool, threshold: Double) -> Double {
        #if os(iOS)
        return PythonHelper.runICPInference(source: source, target: target, isFgr: isFgr, threshold: threshold)
        #elseif os(visionOS)
        let sourceData = Data(source.utf8)
        let targetData = Data(target.utf8)
        let result = NetworkHelper.authenticateTwoPointCloudsSync(sourceData, targetData)
        return result?.fitness ?? 0
        #endif
    }
}

// MARK: - PNLK

extension AuthenticationHelper {
    static private func runPNLKInference(source: String, target: String, threshold: Double) -> Double {
        let sourceData = Data(source.utf8)
        let targetData = Data(target.utf8)
        let result = NetworkHelper.authenticateTwoPointCloudsSync(sourceData, targetData)
        return result?.fitness ?? 0
    }
}

// MARK: - FMR

extension AuthenticationHelper {
    static private func runFMRInference(source: String, target: String, threshold: Double) -> Double {
        let sourceData = Data(source.utf8)
        let targetData = Data(target.utf8)
        let result = NetworkHelper.authenticateTwoPointCloudsSync(sourceData, targetData)
        return result?.fitness ?? 0
    }
}

// MARK: - DeepGMR with TorchScript (LibTorch)

extension AuthenticationHelper {
    static private func runDeepGMRInference(source: String, target: String, threshold: Double) -> Double {
        #if os(iOS)
        guard let sourceTemp = createMLMultiArray(from: source),
              let targetTemp = createMLMultiArray(from: target) else { return 0 }
        
        guard let tMatrix = WorldAuthCoreML.runInference(source: source, target: target, method: "DGMR") else { return 0 }
        
        return PythonHelper.evaluateRegistration(source: sourceTemp, target: targetTemp, tMatrix: tMatrix, threshold: threshold)
        #elseif os(visionOS)
        let sourceData = Data(source.utf8)
        let targetData = Data(target.utf8)
        let result = NetworkHelper.authenticateTwoPointCloudsSync(sourceData, targetData)
        return result?.fitness ?? 0
        #endif
    }
}

// MARK: - Helper Functions

extension AuthenticationHelper {
    
    static func createMLMultiArray(from string: String) -> MLMultiArray? {
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
            LoggerHelper.logError(
                parameters: [
                    .message: "Error creating MLMultiArray: \(error)",
                ]
            )
            return nil
        }
    }
}
