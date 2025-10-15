//
//  NetworkHelper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/19.
//

import UIKit

struct NetworkHelper {
    static private let apiUrl: String = {
        guard let filePath = Bundle.main.path(forResource: "WorldAuth-Info", ofType: "plist") else {
            fatalError("Couldn't find file 'WorldAuth-Info.plist'.")
        }
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "API_URL") as? String else {
            fatalError("Couldn't find key 'API_URL' in 'WorldAuth-Info.plist'.")
        }
        return value
    }()
    
    // MARK: - Response Models
    
    struct PointCloudList: Codable {
        let success: Bool
        let data: [String]?
        let error: String?
        let detail: String?
    }
    
    struct BasicResponse: Codable {
        let success: Bool
        let error: String?
        let detail: String?
    }
    
    struct AuthenticationResult: Codable {
        let success: Bool
        let fitness: Double?
        let error: String?
        let detail: String?
    }
    
    // MARK: - Helpers
    
    private static func parseErrorResponse(data: Data?) -> NSError {
        guard let data = data else {
            return NSError(domain: "No data received", code: 400)
        }
        if let errorResponse = try? JSONDecoder().decode(BasicResponse.self, from: data),
           let errorMsg = errorResponse.error {
            let detailMsg = errorResponse.detail ?? ""
            let fullMsg = detailMsg.isEmpty ? errorMsg : "\(errorMsg): \(detailMsg)"
            return NSError(domain: fullMsg, code: 400)
        }
        return NSError(domain: "Unknown error", code: 400)
    }
    
    static func getPointCloud(completion: @escaping ([SavedPointCloudFile]?, Error?) -> Void) {
        guard let userIdentifier = UIDevice.current.identifierForVendor?.uuidString else { return }
        guard let url = URL(string: apiUrl + "/api/get-point-cloud") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(userIdentifier, forHTTPHeaderField: "U-Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                LoggerHelper.logError(
                    parameters: [
                        .message: "Error getting files: \(error)",
                    ]
                )
                completion(nil, error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let err = NSError(domain: "Invalid response", code: 400)
                LoggerHelper.logError(parameters: [.message: err.localizedDescription])
                completion(nil, err)
                return
            }
            
            guard let data = data else {
                let err = NSError(domain: "No data received", code: 400)
                LoggerHelper.logError(parameters: [.message: err.localizedDescription])
                completion(nil, err)
                return
            }
            
            if httpResponse.statusCode != 200 {
                let err = parseErrorResponse(data: data)
                LoggerHelper.logError(parameters: [.message: "Error with response status code: \(httpResponse.statusCode), \(err.localizedDescription)"])
                completion(nil, err)
                return
            }
            
            do {
                let jsonResponse = try JSONDecoder().decode(PointCloudList.self, from: data)
                if jsonResponse.success, let result = jsonResponse.data {
                    let files = result.map { SavedPointCloudFile(name: $0) }
                    completion(files, nil)
                } else {
                    let errorMsg = jsonResponse.error ?? "Unknown error"
                    let detail = jsonResponse.detail ?? ""
                    let fullMsg = detail.isEmpty ? errorMsg : "\(errorMsg): \(detail)"
                    let err = NSError(domain: fullMsg, code: 400)
                    LoggerHelper.logError(parameters: [.message: "API responded with error: \(fullMsg)"])
                    completion(nil, err)
                }
            } catch {
                LoggerHelper.logError(
                    parameters: [
                        .message: "JSON parsing error: \(error)",
                    ]
                )
                completion(nil, error)
            }
        }
        
        task.resume()
    }
    
    static func registerPointCloud(_ file: Data, completion: @escaping (AuthenticationResult?, Error?) -> Void) {
        guard let userIdentifier = UIDevice.current.identifierForVendor?.uuidString else { return }
        guard let url = URL(string: apiUrl + "/api/register") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(userIdentifier, forHTTPHeaderField: "U-Authorization")
        
        var body = Data()
        body.reserveCapacity(file.count + 1024)
        
        // Use "file" as the form-data key
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"source.ply\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(file)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                LoggerHelper.logError(
                    parameters: [
                        .message: "Error uploading files: \(error)",
                    ]
                )
                completion(nil, error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let err = NSError(domain: "Invalid response", code: 400)
                LoggerHelper.logError(parameters: [.message: err.localizedDescription])
                completion(nil, err)
                return
            }
            
            guard let data = data else {
                let err = NSError(domain: "No data received", code: 400)
                LoggerHelper.logError(parameters: [.message: err.localizedDescription])
                completion(nil, err)
                return
            }
            
            if httpResponse.statusCode != 200 {
                let err = parseErrorResponse(data: data)
                LoggerHelper.logError(parameters: [.message: "Error with response status code: \(httpResponse.statusCode), \(err.localizedDescription)"])
                completion(nil, err)
                return
            }
            
            do {
                let networkResponse = try JSONDecoder().decode(AuthenticationResult.self, from: data)
                if networkResponse.success {
                    completion(networkResponse, nil)
                    LoggerHelper.logInfo(
                        parameters: [
                            .message: "Files uploaded successfully!",
                        ]
                    )
                } else {
                    let errorMsg = networkResponse.error ?? "Unknown error"
                    let detail = networkResponse.detail ?? ""
                    let fullMsg = detail.isEmpty ? errorMsg : "\(errorMsg): \(detail)"
                    let err = NSError(domain: fullMsg, code: 400)
                    LoggerHelper.logError(parameters: [.message: "API responded with error: \(fullMsg)"])
                    completion(nil, err)
                }
            } catch let parseError {
                LoggerHelper.logError(
                    parameters: [
                        .message: "JSON parsing error: \(parseError)",
                    ]
                )
                completion(nil, parseError)
            }
        }
        
        task.resume()
    }
    
    static func authenticatePointCloud(_ file: Data, completion: @escaping (AuthenticationResult?, Error?) -> Void) {
        guard let userIdentifier = UIDevice.current.identifierForVendor?.uuidString else { return }
        guard let url = URL(string: apiUrl + "/api/authenticate") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(userIdentifier, forHTTPHeaderField: "U-Authorization")
        request.setValue(RemoteConfigHelper.shared.authenticationMethod(), forHTTPHeaderField: "AuthorizationMethod")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.reserveCapacity(file.count + 1024)
        
        // Use "file" as the form-data key
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"target.ply\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(file)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                LoggerHelper.logError(
                    parameters: [
                        .message: "Error uploading files: \(error)",
                    ]
                )
                completion(nil, error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let err = NSError(domain: "Invalid response", code: 400)
                LoggerHelper.logError(parameters: [.message: err.localizedDescription])
                completion(nil, err)
                return
            }
            
            guard let data = data else {
                let err = NSError(domain: "No data received", code: 400)
                LoggerHelper.logError(parameters: [.message: err.localizedDescription])
                completion(nil, err)
                return
            }
            
            if httpResponse.statusCode != 200 {
                let err = parseErrorResponse(data: data)
                LoggerHelper.logError(parameters: [.message: "Error with response status code: \(httpResponse.statusCode), \(err.localizedDescription)"])
                completion(nil, err)
                return
            }
            
            do {
                let networkResponse = try JSONDecoder().decode(AuthenticationResult.self, from: data)
                if networkResponse.success {
                    completion(networkResponse, nil)
                    LoggerHelper.logInfo(
                        parameters: [
                            .message: "Files uploaded successfully!",
                        ]
                    )
                } else {
                    let errorMsg = networkResponse.error ?? "Unknown error"
                    let detail = networkResponse.detail ?? ""
                    let fullMsg = detail.isEmpty ? errorMsg : "\(errorMsg): \(detail)"
                    let err = NSError(domain: fullMsg, code: 400)
                    LoggerHelper.logError(parameters: [.message: "API responded with error: \(fullMsg)"])
                    completion(nil, err)
                }
            } catch let parseError {
                LoggerHelper.logError(
                    parameters: [
                        .message: "JSON parsing error: \(parseError)",
                    ]
                )
                completion(nil, parseError)
            }
        }
        
        task.resume()
    }
    
    static func authenticateTwoPointClouds(_ sourceFile: Data, _ targetFile: Data, completion: @escaping (AuthenticationResult?, Error?) -> Void) {
        guard let userIdentifier = UIDevice.current.identifierForVendor?.uuidString else {
            completion(nil, NSError(domain: "Device identifier not available", code: 400))
            return
        }
        guard let url = URL(string: apiUrl + "/api/authenticate-two-point-clouds") else {
            completion(nil, NSError(domain: "Invalid URL", code: 400))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(userIdentifier, forHTTPHeaderField: "U-Authorization")
        request.setValue(RemoteConfigHelper.shared.authenticationMethod(), forHTTPHeaderField: "AuthorizationMethod")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.reserveCapacity(sourceFile.count + targetFile.count + 2048)
        
        // Use "file1" for sourceFile
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file1\"; filename=\"sourceFile.ply\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(sourceFile)
        body.append("\r\n".data(using: .utf8)!)
        
        // Use "file2" for targetFile
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file2\"; filename=\"targetFile.ply\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(targetFile)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, NSError(domain: "Invalid response", code: 400))
                return
            }
            guard let data = data else {
                completion(nil, NSError(domain: "No data received", code: 400))
                return
            }
            if httpResponse.statusCode != 200 {
                if let errorResponse = try? JSONDecoder().decode(AuthenticationResult.self, from: data),
                   let errorMsg = errorResponse.error {
                    let detail = errorResponse.detail ?? ""
                    let fullMsg = detail.isEmpty ? errorMsg : "\(errorMsg): \(detail)"
                    let err = NSError(domain: fullMsg, code: httpResponse.statusCode)
                    completion(nil, err)
                } else {
                    completion(nil, NSError(domain: "Server returned an error", code: httpResponse.statusCode))
                }
                return
            }
            do {
                let result = try JSONDecoder().decode(AuthenticationResult.self, from: data)
                if result.success {
                    completion(result, nil)
                } else {
                    let errorMsg = result.error ?? "Unknown error"
                    let detail = result.detail ?? ""
                    let fullMsg = detail.isEmpty ? errorMsg : "\(errorMsg): \(detail)"
                    let err = NSError(domain: fullMsg, code: 400)
                    completion(nil, err)
                }
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
    }
    
    static func deletePointCloud(fileName: String, completion: @escaping (AuthenticationResult?, Error?) -> Void) {
        guard let userIdentifier = UIDevice.current.identifierForVendor?.uuidString else { return }
        guard let url = URL(string: apiUrl + "/api/delete-point-cloud") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(userIdentifier, forHTTPHeaderField: "U-Authorization")
        request.setValue(fileName, forHTTPHeaderField: "FileRequest")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                LoggerHelper.logError(
                    parameters: [
                        .message: "Error deleting files: \(error)",
                    ]
                )
                completion(nil, error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let err = NSError(domain: "Invalid response", code: 400)
                LoggerHelper.logError(parameters: [.message: err.localizedDescription])
                completion(nil, err)
                return
            }
            
            guard let data = data else {
                let err = NSError(domain: "No data received", code: 400)
                LoggerHelper.logError(parameters: [.message: err.localizedDescription])
                completion(nil, err)
                return
            }
            
            if httpResponse.statusCode != 200 {
                let err = parseErrorResponse(data: data)
                LoggerHelper.logError(parameters: [.message: "Error with response status code: \(httpResponse.statusCode), \(err.localizedDescription)"])
                completion(nil, err)
                return
            }
            
            do {
                let networkResponse = try JSONDecoder().decode(BasicResponse.self, from: data)
                if networkResponse.success {
                    let authResult = AuthenticationResult(success: true, fitness: nil, error: nil, detail: nil)
                    completion(authResult, nil)
                    LoggerHelper.logInfo(
                        parameters: [
                            .message: "Files deleted successfully!",
                        ]
                    )
                } else {
                    let errorMsg = networkResponse.error ?? "Unknown error"
                    let detail = networkResponse.detail ?? ""
                    let fullMsg = detail.isEmpty ? errorMsg : "\(errorMsg): \(detail)"
                    let err = NSError(domain: fullMsg, code: 400)
                    LoggerHelper.logError(parameters: [.message: "API responded with error: \(fullMsg)"])
                    completion(nil, err)
                }
            } catch let parseError {
                LoggerHelper.logError(
                    parameters: [
                        .message: "JSON parsing error: \(parseError)",
                    ]
                )
                completion(nil, parseError)
            }
        }
        
        task.resume()
    }
}

// MARK: Helper

extension NetworkHelper {
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

