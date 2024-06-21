//
//  NetworkHelper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/19.
//

import Foundation

struct NetworkHelper {
    static func checkPlyData(_ files: [Data], completion: @escaping (Bool, Error?) -> Void) {
        guard let url = URL(string: "https://yourserver.com/upload") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        for (index, fileData) in files.enumerated() {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\(index + 1)\"; filename=\"file\(index + 1).ply\"\r\n".data(using: .utf8)!)
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

            completion(true, nil)
            print("Files uploaded successfully!")
        }

        task.resume()
    }
}
