//
//  AuthenticationHelper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/03/11.
//

import CoreML

struct AuthenticationHelper {  }

// MARK: DeepGMR

extension AuthenticationHelper {
    static private func loadDeepGMR() -> DeepGMR {
        guard let model = try? DeepGMR(configuration: MLModelConfiguration()) else {
            fatalError("Failed to load DeepGMR model.")
        }
        return model
    }
    
    static func runDeepGMRInference(source: String, target: String) -> Double {
        if let source = AuthenticationHelper.createMLMultiArray(from: source), let target = AuthenticationHelper.createMLMultiArray(from: target) {
            let input = DeepGMRInput(pts1: source, pts2: target)
            let model = loadDeepGMR()
            do {
                let prediction = try model.prediction(input: input)
                return Double(prediction.const_0[0].floatValue)
            } catch {
                print(error.localizedDescription)
            }
            
        }
        return 0
    }
}

// MARK: Helper

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
            let shape: [NSNumber] = [1 as NSNumber, rowCount as NSNumber, colCount as NSNumber]
            let mlArray = try MLMultiArray(shape: shape, dataType: .float32)
            
            let flattenedValues = points.flatMap { $0 }

            for (index, value) in flattenedValues.enumerated() {
                mlArray[index] = NSNumber(value: value)
            }
            
            return mlArray
        } catch {
            print("Error creating MLMultiArray: \(error)")
            return nil
        }
    }
}
