//
//  NetworkHelper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/19.
//

import Foundation

struct NetworkHelper {
    static func checkPlyData(_ files: [Data], completion: @escaping (Bool, Error?) -> Void) {
        guard let url = URL(string: "https://yourserver.com/api/authenticate/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        for (index, fileData) in files.enumerated() {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"files\"; filename=\"file\(index + 1).ply\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error uploading files: \(error)")
                completion(false, error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Error with response status code")
                completion(false, nil)
                return
            }

            guard let data = data else {
                print("No data received")
                completion(false, nil)
                return
            }

            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let result = jsonResponse["result"] as? Bool {
                        completion(result, nil)
                        return
                    }
                }
            } catch let parseError {
                print("JSON parsing error: \(parseError)")
                completion(false, parseError)
                return
            }

            completion(false, nil)
            print("Files uploaded successfully!")
        }

        task.resume()
    }

}
