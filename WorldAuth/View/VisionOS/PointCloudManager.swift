//
//  PointCloudManager.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/06/03.
//


import SwiftUI

// Shared state manager for point cloud operations
class PointCloudManager: ObservableObject {
    static let shared = PointCloudManager()
    
    @Published var pointCount: Int = 0
    @Published var debugText: String = "Ready to start scanning..."
    @Published var exportedFileURL: URL?
    @Published var isScanning: Bool = false
    @Published var savedFiles: [SavedPointCloudFile] = []
    
    var pointCloudGenerator: SceneReconstructionPointCloudGenerator?
    
    private init() {
        loadSavedFiles()
    } // Singleton pattern
    
    func updatePointCount() {
        if let generator = pointCloudGenerator {
            let currentCount = generator.exportPointCloud().count
            if currentCount != pointCount {
                pointCount = currentCount
            }
        }
    }
    
    func exportPointCloud(completion: @escaping (Bool) -> Void) {
        guard let generator = pointCloudGenerator else {
            completion(false) // Notify failure if generator is nil
            return
        }
        
        let points = generator.exportPointCloud()
        let plyString = generator.exportPointCloudAsPLY()
        
        print("Saved \(points.count) points")
        
        // Create a more accessible filename with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let fileName = "VisionPro_PointCloud_\(timestamp).ply"
        
        // Save to Documents directory
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            do {
                try plyString.write(to: fileURL, atomically: true, encoding: .utf8)
                exportedFileURL = fileURL
                pointCount = points.count
                debugText = "✅ Room template saved!"
                print("Point cloud saved to Documents: \(fileURL.path)")
                
                Task {
                    await pointCloudGenerator?.clearPointCloud()
                    await MainActor.run {
                        exportedFileURL = nil
                        pointCount = 0
                        loadSavedFiles()
                    }
                    
                    completion(true) // Notify success
                }
            } catch {
                print("Error saving to Documents: \(error.localizedDescription)")
                debugText = "❌ Failed to save room template: \(error.localizedDescription)"
                completion(false) // Notify failure
            }
        } else {
            completion(false) // Notify failure if Documents directory is not found
        }
    }
    
    func authenticatePointCloud() -> Double {
        guard let generator = pointCloudGenerator else { return 0 }
        let plyString = generator.exportPointCloudAsPLY()
        
        var highestResult: Double = 0
        
        for file in FileHelper.getFileList() {
            let targetString = FileHelper.getDataStringByName(fileName: file.lastPathComponent)
            
            let result = AuthenticationHelper.runInference(source: plyString, target: targetString)
            highestResult = max(highestResult, result)
        }
        
        Task {
            await pointCloudGenerator?.clearPointCloud()
            await MainActor.run {
                exportedFileURL = nil
                pointCount = 0
            }
        }
        
        return highestResult
    }
    
    func loadSavedFiles() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey], options: [])
            
            savedFiles = fileURLs.compactMap { url in
                guard url.pathExtension.lowercased() == "ply" else { return nil }
                
                let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
                let creationDate = attributes?[.creationDate] as? Date ?? Date()
                let fileSize = FileHelper.getFileSize(url: url)
                
                // Try to extract point count from filename or file content
                let pointCount = PointCloudHelper.extractPointCountFromFile(url: url)
                
                return SavedPointCloudFile(
                    name: url.lastPathComponent,
                    url: url,
                    pointCount: pointCount,
                    dateCreated: creationDate,
                    fileSize: fileSize
                )
            }.sorted { $0.dateCreated ?? Date() > $1.dateCreated ?? Date() }
            
        } catch {
            print("Error loading saved files: \(error.localizedDescription)")
        }
    }
    
    func deleteFile(_ file: SavedPointCloudFile) {
        do {
            try FileManager.default.removeItem(at: file.url!)
            savedFiles.removeAll { $0.id == file.id }
            debugText = "File deleted: \(file.name)"
        } catch {
            debugText = "Error deleting file: \(error.localizedDescription)"
        }
    }
    
    func clearPointCloud() {
        Task {
            await pointCloudGenerator?.clearPointCloud()
            await MainActor.run {
                exportedFileURL = nil
                pointCount = 0
                debugText = "Scanned room template cleared. Continue scanning..."
            }
        }
    }
}
