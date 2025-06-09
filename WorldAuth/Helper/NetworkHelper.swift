//
//  NetworkHelper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/19.
//

import UIKit

struct NetworkHelper {
    static private var apiUrl: String {
        guard let filePath = Bundle.main.path(forResource: "WorldAuth-Info", ofType: "plist") else {
            fatalError("Couldn't find file 'WorldAuth-Info.plist'.")
        }
        
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "API_URL") as? String else {
            fatalError("Couldn't find key 'API_URL' in 'WorldAuth-Info.plist'.")
        }
        return value
    }
    
    static func getPointCloud(completion: @escaping ([SavedPointCloudFile]?, Error?) -> Void) {
        guard let userIdentifier = UIDevice.current.identifierForVendor?.uuidString else { return }
        guard let url = URL(string: apiUrl + "/api/get_point_cloud/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(userIdentifier, forHTTPHeaderField: "Authorization")
        
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
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                LoggerHelper.logError(
                    parameters: [
                        .message: "Error with response status code",
                    ]
                )
                completion(nil, NSError(domain: "Error with response status code", code: httpResponse.statusCode))
                return
            }
            
            guard let data = data else {
                LoggerHelper.logError(
                    parameters: [
                        .message: "No data received",
                    ]
                )
                completion(nil, NSError(domain: "No data received", code: 400))
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let result = jsonResponse["data"] as? [String] {
                        let data = result.map { SavedPointCloudFile(name: $0) }
                        completion(data, nil)
                        return
                    }
                }
            } catch let parseError {
                LoggerHelper.logError(
                    parameters: [
                        .message: "JSON parsing error: \(parseError)",
                    ]
                )
                completion(nil, parseError)
                return
            }
        }
        
        task.resume()
    }
    
    static func registerPointCloud(_ file: Data, completion: @escaping (AuthenticationResult?, Error?) -> Void) {
        guard let userIdentifier = UIDevice.current.identifierForVendor?.uuidString else { return }
        guard let url = URL(string: apiUrl + "/api/register/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(userIdentifier, forHTTPHeaderField: "Authorization")
        
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"files\"; filename=\"source.ply\"\r\n".data(using: .utf8)!)
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
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                LoggerHelper.logError(
                    parameters: [
                        .message: "Error with response status code",
                    ]
                )
                completion(nil, NSError(domain: "Error with response status code", code: httpResponse.statusCode))
                return
            }
            
            guard let data = data else {
                LoggerHelper.logError(
                    parameters: [
                        .message: "No data received",
                    ]
                )
                completion(nil, NSError(domain: "No data received", code: 400))
                return
            }
            
            do {
                let networkResponse = try JSONDecoder().decode(AuthenticationResult.self, from: data)
                completion(networkResponse, nil)
                LoggerHelper.logInfo(
                    parameters: [
                        .message: "Files uploaded successfully!",
                    ]
                )
                return
            } catch let parseError {
                LoggerHelper.logError(
                    parameters: [
                        .message: "JSON parsing error: \(parseError)",
                    ]
                )
                completion(nil, parseError)
                return
            }
        }
        
        task.resume()
    }
    
    static func authenticatePointCloud(_ file: Data, completion: @escaping (AuthenticationResult?, Error?) -> Void) {
        guard let userIdentifier = UIDevice.current.identifierForVendor?.uuidString else { return }
        guard let url = URL(string: apiUrl + "/api/authenticate/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(userIdentifier, forHTTPHeaderField: "Authorization")
        request.setValue(RemoteConfigProvider.shared.authenticationMethod(), forHTTPHeaderField: "AuthorizationMethod")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"files\"; filename=\"target.ply\"\r\n".data(using: .utf8)!)
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
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                LoggerHelper.logError(
                    parameters: [
                        .message: "Error with response status code",
                    ]
                )
                completion(nil, NSError(domain: "Error with response status code", code: httpResponse.statusCode))
                return
            }
            
            guard let data = data else {
                LoggerHelper.logError(
                    parameters: [
                        .message: "No data received",
                    ]
                )
                completion(nil, NSError(domain: "No data received", code: 400))
                return
            }
            
            do {
                let networkResponse = try JSONDecoder().decode(AuthenticationResult.self, from: data)
                completion(networkResponse, nil)
                LoggerHelper.logInfo(
                    parameters: [
                        .message: "Files uploaded successfully!",
                    ]
                )
                return
            } catch let parseError {
                LoggerHelper.logError(
                    parameters: [
                        .message: "JSON parsing error: \(parseError)",
                    ]
                )
                completion(nil, parseError)
                return
            }
        }
        
        task.resume()
    }
    
    static func authenticateTwoPointClouds(_ sourceFile: Data, _ targetFile: Data, completion: @escaping (AuthenticationResult?, Error?) -> Void) {
        guard let userIdentifier = UIDevice.current.identifierForVendor?.uuidString else {
            completion(nil, NSError(domain: "Device identifier not available", code: 400))
            return
        }
        guard let url = URL(string: apiUrl + "/api/authenticate_two/") else {
            completion(nil, NSError(domain: "Invalid URL", code: 400))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(userIdentifier, forHTTPHeaderField: "Authorization")
        request.setValue(RemoteConfigProvider.shared.authenticationMethod(), forHTTPHeaderField: "AuthorizationMethod")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add source file under "files"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"files\"; filename=\"sourceFile.ply\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(sourceFile)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add target file under "files"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"files\"; filename=\"targetFile.ply\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(targetFile)
        body.append("\r\n".data(using: .utf8)!)
        
        // Close the boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                completion(nil, NSError(domain: "Server returned an error", code: httpResponse.statusCode))
                return
            }
            guard let data = data else {
                completion(nil, NSError(domain: "No data received", code: 400))
                return
            }
            do {
                let result = try JSONDecoder().decode(AuthenticationResult.self, from: data)
                completion(result, nil)
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
    }
    
    static func deletePointCloud(fileName: String, completion: @escaping (AuthenticationResult?, Error?) -> Void) {
        guard let userIdentifier = UIDevice.current.identifierForVendor?.uuidString else { return }
        guard let url = URL(string: apiUrl + "/api/delete_point_cloud/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(userIdentifier, forHTTPHeaderField: "Authorization")
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
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                LoggerHelper.logError(
                    parameters: [
                        .message: "Error with response status code",
                    ]
                )
                completion(nil, NSError(domain: "Error with response status code", code: httpResponse.statusCode))
                return
            }
            
            guard let data = data else {
                LoggerHelper.logError(
                    parameters: [
                        .message: "No data received",
                    ]
                )
                completion(nil, NSError(domain: "No data received", code: 400))
                return
            }
            
            do {
                let networkResponse = try JSONDecoder().decode(AuthenticationResult.self, from: data)
                completion(networkResponse, nil)
                LoggerHelper.logInfo(
                    parameters: [
                        .message: "Files deleted successfully!",
                    ]
                )
                return
            } catch let parseError {
                LoggerHelper.logError(
                    parameters: [
                        .message: "JSON parsing error: \(parseError)",
                    ]
                )
                completion(nil, parseError)
                return
            }
        }
        
        task.resume()
    }
    
    static func uploadData(_ file: Data, fileName: String = "archive", completion: @escaping (AuthenticationResult?, Error?) -> Void) {
        guard let userIdentifier = UIDevice.current.identifierForVendor?.uuidString else { return }
        guard let url = URL(string: apiUrl + "/api/save_data/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(userIdentifier, forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/zip\r\n\r\n".data(using: .utf8)!)
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
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                LoggerHelper.logError(
                    parameters: [
                        .message: "Error with response status code",
                    ]
                )
                completion(nil, NSError(domain: "Error with response status code", code: httpResponse.statusCode))
                return
            }
            
            guard let data = data else {
                LoggerHelper.logError(
                    parameters: [
                        .message: "No data received",
                    ]
                )
                completion(nil, NSError(domain: "No data received", code: 400))
                return
            }
            
            do {
                let networkResponse = try JSONDecoder().decode(AuthenticationResult.self, from: data)
                completion(networkResponse, nil)
                LoggerHelper.logInfo(
                    parameters: [
                        .message: "Files uploaded successfully!",
                    ]
                )
                return
            } catch let parseError {
                LoggerHelper.logError(
                    parameters: [
                        .message: "JSON parsing error: \(parseError)",
                    ]
                )
                completion(nil, parseError)
                return
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
