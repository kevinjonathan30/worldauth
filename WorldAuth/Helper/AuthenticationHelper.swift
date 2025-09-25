//
//  AuthenticationHelper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/03/11.
//

import Foundation
import CoreML

struct AuthenticationHelper {
    
    static func runInference(source: String, target: String) -> Double {
        var threshold: Double = 0.0
        var authTime: Double = 0.0
        var fitness: Double = 0.0
        let method: String = RemoteConfigHelper.shared.authenticationMethod()
        
        let startTime = Date()
        
        switch method {
        case "ICP":
            threshold = 0.06
            fitness = runICPInference(source: source, target: target, isFgr: false, threshold: threshold)
        case "FGR":
            threshold = 0.09
            fitness = runICPInference(source: source, target: target, isFgr: true, threshold: threshold)
        case "PNLK":
            threshold = 0.14
            fitness = runPNLKInference(source: source, target: target, threshold: threshold)
        case "FMR":
            threshold = 0.08
            fitness = runFMRInference(source: source, target: target, threshold: threshold)
        case "DGMR":
            threshold = 0.14
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
        let sourceData = Data(source.utf8)
        let targetData = Data(target.utf8)
        let result = NetworkHelper.authenticateTwoPointCloudsSync(sourceData, targetData)
        return result?.fitness ?? 0
    }
}
