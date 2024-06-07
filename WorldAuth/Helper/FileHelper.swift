//
//  FileHelper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/07.
//

import Foundation

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
            print(error.localizedDescription)
            return nil
        }
    }
    
    static func getFileList(atDirectory: String = "") -> [URL] {
        let fileManager = FileManager.default
        
        guard let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return [] }
        let filePathURL = directoryURL.appendingPathComponent(atDirectory)
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: filePathURL, includingPropertiesForKeys: nil)
            return fileURLs
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
    
    static func deleteFile(atDirectory: String = "", fileName: String) -> Bool {
        let fileManager = FileManager.default
        
        guard let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return false }
        let filePathURL = directoryURL.appendingPathComponent(atDirectory)
        
        do {
            try fileManager.removeItem(at: filePathURL)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
}
