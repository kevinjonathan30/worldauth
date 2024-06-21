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
            guard fileManager.fileExists(atPath: filePathURL.path()) else { return [] }
            let fileURLs = try fileManager.contentsOfDirectory(at: filePathURL, includingPropertiesForKeys: nil)
            return fileURLs
        } catch {
            print(error.localizedDescription)
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
            print(error.localizedDescription)
            return nil
        }
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
            print(error.localizedDescription)
            return false
        }
    }
    
//    private func shareFiles() {
//        guard !viewModel.capturedPlyFileURLs.isEmpty, !viewModel.capturedImageURLs.isEmpty else {
//            print("No PLY or JPG files found")
//            return
//        }
//
//        // Disable point cloud and mesh state everytime user tries to share, and revert it later
//        viewModel.showPointCloudTemp = showPointCloud
//        showPointCloud = false
//        viewModel.showMeshTemp = showMesh
//        showMesh = false
//
//        let fileManager = FileManager.default
//        let dateString = DateHelper.getStringFromDate()
//        let zipFileName = "PointCloud_\(dateString).zip"
//        guard let documentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
//        let zipFileURL = documentsDirectoryURL.appendingPathComponent(zipFileName)
//
//        do {
//            let archive = try Archive(url: zipFileURL, accessMode: .create)
//            for plyFileURL in viewModel.capturedPlyFileURLs {
//                try archive.addEntry(with: plyFileURL.lastPathComponent, relativeTo: documentsDirectoryURL)
//            }
//            for imageFileURL in viewModel.capturedImageURLs {
//                try archive.addEntry(with: imageFileURL.lastPathComponent, relativeTo: documentsDirectoryURL)
//            }
//
//            DispatchQueue.main.async {
//                let activityViewController = UIActivityViewController(activityItems: [zipFileURL], applicationActivities: nil)
//                activityViewController.completionWithItemsHandler =  { _, _, _, _ in
//                    showPointCloud = viewModel.showPointCloudTemp
//                    showMesh = viewModel.showMeshTemp
//                }
//                if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
//                    scene.windows.first?.rootViewController?.present(
//                        activityViewController,
//                        animated: true,
//                        completion: nil
//                    )
//                }
//            }
//
//        } catch {
//            print(error.localizedDescription)
//        }
//    }
}
