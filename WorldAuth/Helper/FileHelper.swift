//
//  FileHelper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/07.
//

import SwiftUI

struct FileHelper {
    static func saveFile(data: Data, atDirectory directoryName: String = "", fileName: String) -> URL? {
        let fileManager = FileManager.default
        
        guard let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let filePathURL = directoryURL.appendingPathComponent(directoryName)
        
        do {
            try FileManager.default.createDirectory(atPath: filePathURL.path(), withIntermediateDirectories: true, attributes: nil)
            let fileNameURL = filePathURL.appendingPathComponent(fileName)
            try data.write(to: fileNameURL, options: [.atomic, .completeFileProtection])
            return fileNameURL
        } catch {
            LoggerHelper.logError(
                parameters: [
                    .message: error.localizedDescription,
                ]
            )
            return nil
        }
    }
    
    static func getFileList(atDirectory: String = "") -> [URL] {
        let fileManager = FileManager.default
        
        guard let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return [] }
        let filePathURL = directoryURL.appendingPathComponent(atDirectory)
        
        do {
            guard fileManager.fileExists(atPath: filePathURL.path()) else { return [] }
            let fileURLs = try fileManager.contentsOfDirectory(at: filePathURL, includingPropertiesForKeys: nil)
            return fileURLs
        } catch {
            LoggerHelper.logError(
                parameters: [
                    .message: error.localizedDescription,
                ]
            )
            return []
        }
    }
    
    static func getDataByName(atDirectory: String = "", fileName: String) -> Data? {
        let fileManager = FileManager.default
        
        guard let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        
        let filePathURL = directoryURL.appendingPathComponent(atDirectory)
        let fileNameURL = filePathURL.appendingPathComponent(fileName)
        
        do {
            let data = try Data(contentsOf: fileNameURL)
            return data
        } catch {
            LoggerHelper.logError(
                parameters: [
                    .message: error.localizedDescription,
                ]
            )
            return nil
        }
    }
    
    static func getDataStringByName(atDirectory: String = "", fileName: String) -> String {
        if let data = FileHelper.getDataByName(atDirectory: atDirectory, fileName: fileName) {
            if let content = String(data: data, encoding: .utf8) {
                return content
            } else {
                LoggerHelper.logError(
                    parameters: [
                        .message: "Failed to decode data into a string.",
                    ]
                )
            }
        } else {
            LoggerHelper.logError(
                parameters: [
                    .message: "Failed to retrieve data.",
                ]
            )
        }
        return ""
    }
    
    static func deleteFile(atDirectory: String = "", fileName: String) -> Bool {
        let fileManager = FileManager.default
        
        guard let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return false }
        let filePathURL = directoryURL.appendingPathComponent(atDirectory)
        let fileNameURL = filePathURL.appendingPathComponent(fileName)
        
        do {
            try fileManager.removeItem(at: fileNameURL)
            return true
        } catch {
            LoggerHelper.logError(
                parameters: [
                    .message: error.localizedDescription,
                ]
            )
            return false
        }
    }
    
    static func sharePLYFile(url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let topController = windowScene.windows.first?.rootViewController {
                topController.present(activityViewController, animated: true, completion: nil)
            }
        }
    }
    
    static func getFileSize(url: URL) -> String? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                let formatter = ByteCountFormatter()
                formatter.countStyle = .file
                return formatter.string(fromByteCount: fileSize)
            }
        } catch {
            print("Error getting file size: \(error.localizedDescription)")
        }
        return nil
    }
}
