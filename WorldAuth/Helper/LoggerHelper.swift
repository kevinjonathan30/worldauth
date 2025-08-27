//
//  LoggerHelper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/05/21.
//

import SwiftUI

//// Sending a debug log
//LoggerHelper.logDebug(event: "Debug event", extra: ["key": "value"])
//
//// Sending an info log
//LoggerHelper.logInfo(event: "Info event", extra: ["userId": 123, "action": "login"])
//
//// Sending an error log
//LoggerHelper.logError(event: "Error event", extra: ["errorCode": 404, "message": "Not Found"])

struct LoggerHelper {
    static private var userId: Int {
        guard let filePath = Bundle.main.path(forResource: "WorldAuth-Info", ofType: "plist") else {
            fatalError("Couldn't find file 'WorldAuth-Info.plist'.")
        }
        
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "LOGGER_USER") as? Int else {
            fatalError("Couldn't find key 'LOGGER_USER' in 'WorldAuth-Info.plist'.")
        }
        return value
    }
    
    static private var apiKey: String {
        guard let filePath = Bundle.main.path(forResource: "WorldAuth-Info", ofType: "plist") else {
            fatalError("Couldn't find file 'WorldAuth-Info.plist'.")
        }
        
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "LOGGER_KEY") as? String else {
            fatalError("Couldn't find key 'LOGGER_KEY' in 'WorldAuth-Info.plist'.")
        }
        return value
    }
    
    static private var urlString: String {
        guard let filePath = Bundle.main.path(forResource: "WorldAuth-Info", ofType: "plist") else {
            fatalError("Couldn't find file 'WorldAuth-Info.plist'.")
        }
        
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "LOGGER_API") as? String else {
            fatalError("Couldn't find key 'LOGGER_API' in 'WorldAuth-Info.plist'.")
        }
        return value
    }
    
    private static let url = URL(string: urlString)!
}

extension LoggerHelper {
    static private func hasUserConsented() -> Bool {
        return UserDefaults.standard.bool(forKey: "userConsented")
    }
    
    static private func sendLog(
        event: String,
        level: String? = nil,
        parameters: [LoggerCategory: Any]? = nil,
        debugInfo: String
    ) {
        guard hasUserConsented() else { return }
        guard !event.isEmpty else {
            print("The 'event' field is required.")
            return
        }
        
        var extra = parameters
        let platform = UIDevice.current.systemName
        extra?[.platform] = platform
        extra?[.debugInfo] = debugInfo
        
        // Sort and convert extra data into a single dictionary
        let processedExtra: [String: Any]? = extra?.reduce(into: [String: Any]()) { result, pair in
            result[pair.key.rawValue] = pair.value
        }
        
        // Serialize sorted extra data to JSON string
        let extraString: String
        if let processedExtra = processedExtra, let jsonData = try? JSONSerialization.data(withJSONObject: processedExtra, options: [.sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            extraString = jsonString
        } else {
            extraString = "{}"
        }
        
        // Construct the log data
        let timestamp = Int(Date().timeIntervalSince1970 * 1_000_000_000)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        dateFormatter.timeZone = TimeZone.current
        let formattedTimestamp = dateFormatter.string(from: Date())
        
        var logData: [String: Any] = [
            "streams": [
                [
                    "stream": ["event": event],
                    "values": [[String(timestamp), extraString]]
                ]
            ]
        ]
        
        // Add the log level to the stream if provided
        if let level = level,
           var streams = logData["streams"] as? [[String: Any]],
           var stream = streams.first?["stream"] as? [String: Any] {
            stream["level"] = level
            streams[0]["stream"] = stream
            logData["streams"] = streams
        }
        
        // Serialize log data to JSON
        guard let logDataJSON = try? JSONSerialization.data(withJSONObject: logData, options: []) else {
            print("Failed to serialize log data.")
            return
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let credentials = "\(userId):\(apiKey)"
        if let credentialsData = credentials.data(using: .utf8)?.base64EncodedString() {
            request.addValue("Basic \(credentialsData)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = logDataJSON
        
        // Send the log data
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to send log: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 {
                print("\(event) \(formattedTimestamp) \(extraString)")
            } else {
                print("Failed to send log, status code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            }
        }
        task.resume()
    }
    
    // Convenience methods for different log levels
    static func logDebug(
        event: String = #function,
        parameters: [LoggerCategory: Any]? = nil,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) {
        sendLog(event: event.components(separatedBy: "(").first ?? event, level: "debug", parameters: parameters, debugInfo: "[\(file):\(line) - \(function)]")
    }
    
    static func logInfo(
        event: String = #function,
        parameters: [LoggerCategory: Any]? = nil,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) {
        sendLog(event: event.components(separatedBy: "(").first ?? event, level: "info", parameters: parameters, debugInfo: "[\(file):\(line) - \(function)]")
    }
    
    static func logError(
        event: String = #function,
        parameters: [LoggerCategory: Any]? = nil,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) {
        sendLog(event: event.components(separatedBy: "(").first ?? event, level: "error", parameters: parameters, debugInfo: "[\(file):\(line) - \(function)]")
    }
}

extension LoggerHelper {
    private static func strippedFunctionName(_ function: String) -> String {
        if let index = function.firstIndex(of: "(") {
            return String(function[..<index])
        }
        return function
    }
}
