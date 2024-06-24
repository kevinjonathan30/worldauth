//
//  NetworkHelper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/19.
//

import Foundation

struct NetworkHelper {
    static func checkPlyData(_ files: [Data], completion: @escaping (NetworkResponse?, Error?) -> Void) {
        guard let url = URL(string: "http://10.24.86.250:8000/api/authenticate/") else { return }
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
                let networkResponse = try JSONDecoder().decode(NetworkResponse.self, from: data)
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
}
