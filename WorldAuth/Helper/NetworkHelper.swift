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
    
    static func getPointCloud(completion: @escaping ([WorldTemplate]?, Error?) -> Void) {
        guard let userIdentifier = UIDevice.current.identifierForVendor?.uuidString else { return }
        guard let url = URL(string: apiUrl + "/api/get_point_cloud/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(userIdentifier, forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error getting files: \(error)")
                completion(nil, error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Error with response status code")
                completion(nil, nil)
                return
            }

            guard let data = data else {
                print("No data received")
                completion(nil, nil)
                return
            }

            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let result = jsonResponse["data"] as? [String] {
                        let data = result.map { WorldTemplate(pcdName: $0) }
                        completion(data, nil)
                        return
                    }
                }
            } catch let parseError {
                print("JSON parsing error: \(parseError)")
                completion(nil, parseError)
                return
            }
        }

        task.resume()
    }
    
    static func registerPointCloud(_ file: Data, completion: @escaping (AuthenticationResponse?, Error?) -> Void) {
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
                print("Error uploading files: \(error)")
                completion(nil, error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Error with response status code")
                completion(nil, nil)
                return
            }

            guard let data = data else {
                print("No data received")
                completion(nil, nil)
                return
            }

            do {
                let networkResponse = try JSONDecoder().decode(AuthenticationResponse.self, from: data)
                completion(networkResponse, nil)
                print("Files uploaded successfully!")
                return
            } catch let parseError {
                print("JSON parsing error: \(parseError)")
                completion(nil, parseError)
                return
            }
        }

        task.resume()
    }
    
    static func authenticatePointCloud(_ file: Data, completion: @escaping (AuthenticationResponse?, Error?) -> Void) {
        guard let userIdentifier = UIDevice.current.identifierForVendor?.uuidString else { return }
        guard let url = URL(string: apiUrl + "/api/authenticate/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(userIdentifier, forHTTPHeaderField: "Authorization")

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
                print("Error uploading files: \(error)")
                completion(nil, error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Error with response status code")
                completion(nil, nil)
                return
            }

            guard let data = data else {
                print("No data received")
                completion(nil, NSError(domain: "No data received", code: 400))
                return
            }

            do {
                let networkResponse = try JSONDecoder().decode(AuthenticationResponse.self, from: data)
                completion(networkResponse, nil)
                print("Files uploaded successfully!")
                return
            } catch let parseError {
                print("JSON parsing error: \(parseError)")
                completion(nil, parseError)
                return
            }
        }

        task.resume()
    }
    
    static func deletePointCloud(fileName: String, completion: @escaping (AuthenticationResponse?, Error?) -> Void) {
        guard let userIdentifier = UIDevice.current.identifierForVendor?.uuidString else { return }
        guard let url = URL(string: apiUrl + "/api/delete_point_cloud/\(fileName)/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(userIdentifier, forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error deleting files: \(error)")
                completion(nil, error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Error with response status code")
                completion(nil, nil)
                return
            }

            guard let data = data else {
                print("No data received")
                completion(nil, nil)
                return
            }

            do {
                let networkResponse = try JSONDecoder().decode(AuthenticationResponse.self, from: data)
                completion(networkResponse, nil)
                print("Files deleted successfully!")
                return
            } catch let parseError {
                print("JSON parsing error: \(parseError)")
                completion(nil, parseError)
                return
            }
        }

        task.resume()
    }
}
