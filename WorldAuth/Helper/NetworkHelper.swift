//
//  NetworkHelper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/19.
//

import Foundation

struct NetworkHelper {
    static func uploadPLYData(_ plyData: Data) {
        guard let url = URL(string: "https://yourserver.com/upload") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = plyData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error uploading point cloud: \(error)")
                return
            }
            
            print("Point cloud uploaded successfully!")
        }
        
        task.resume()
    }
}
