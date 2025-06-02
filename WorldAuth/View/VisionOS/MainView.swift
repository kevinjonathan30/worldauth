//
//  MainView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/02/06.
//

import SwiftUI
import UniformTypeIdentifiers

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
    
    func exportPointCloud() {
        guard let generator = pointCloudGenerator else { return }
        
        let points = generator.exportPointCloud()
        let plyString = generator.exportPointCloudAsPLY()
        
        print("Exported \(points.count) points")
        
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
                debugText = "✅ Point cloud exported! \(points.count) points saved."
                print("Point cloud saved to Documents: \(fileURL.path)")
                
                // Add to saved files list
                let savedFile = SavedPointCloudFile(
                    name: fileName,
                    url: fileURL,
                    pointCount: points.count,
                    dateCreated: Date(),
                    fileSize: FileHelper.getFileSize(url: fileURL)
                )
                savedFiles.append(savedFile)
                
                return
            } catch {
                print("Error saving to Documents: \(error.localizedDescription)")
                debugText = "❌ Failed to export point cloud: \(error.localizedDescription)"
            }
        }
    }
    
    func authenticatePointCloud(plyString: String) {
        // TODO: Process the PLY online, combine some point cloud helper functions for both iOS and VisionOS
        var highestResult: Double = 0
        
        for file in FileHelper.getFileList() {
            let targetString = FileHelper.getDataStringByName(fileName: file.lastPathComponent)
            
            let result = AuthenticationHelper.runInference(source: plyString, target: targetString)
            highestResult = max(highestResult, result)
        }
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
                debugText = "Point cloud cleared. Continue scanning..."
            }
        }
    }
}

struct MainView: View {
    @ObservedObject private var pointCloudManager = PointCloudManager.shared
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    var body: some View {
        NavigationSplitView {
            HStack(spacing: 0) {
                // Main content (left side) - Takes most of the space
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("WorldAuth")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Scan your environment to capture 3D point cloud data")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    Spacer()
                    
                    // Status Section
                    VStack(spacing: 12) {
                        // Status Text
                        Text(pointCloudManager.debugText)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        
                        // Point Count
                        if pointCloudManager.pointCount > 0 {
                            HStack {
                                Image(systemName: "point.3.connected.trianglepath.dotted")
                                    .foregroundColor(.blue)
                                Text("Points Captured: \(pointCloudManager.pointCount)")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        // Success Message with file info
                        if pointCloudManager.exportedFileURL != nil {
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Point cloud exported successfully!")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                }
                                
                                if let url = pointCloudManager.exportedFileURL {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("File: \(url.lastPathComponent)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        if let fileSize = getFileSize(url: url) {
                                            Text("Size: \(fileSize)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    
                    Spacer()
                    
                    // Control Buttons
                    VStack(spacing: 16) {
                        // Scanning Control
                        if !pointCloudManager.isScanning {
                            Button(action: startScanning) {
                                HStack {
                                    Image(systemName: "camera.metering.center.weighted")
                                    Text("Start Scanning")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        } else {
                            Button(action: stopScanning) {
                                HStack {
                                    Image(systemName: "stop.circle")
                                    Text("Stop Scanning")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                        
                        // Export and Clear Controls
                        if pointCloudManager.isScanning || pointCloudManager.pointCount > 0 {
                            VStack(spacing: 12) {
                                // Export button
                                Button(action: {
                                    pointCloudManager.exportPointCloud()
                                }) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Export Point Cloud")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                                .disabled(pointCloudManager.pointCount == 0)
                                
                                // Clear button
                                Button(action: {
                                    pointCloudManager.clearPointCloud()
                                }) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Clear Point Cloud")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                                .disabled(pointCloudManager.pointCount == 0)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
        } detail: {
            // File list sidebar (right side) - Compact sidebar
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("My Room Template")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: {
                            pointCloudManager.loadSavedFiles()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    if pointCloudManager.savedFiles.isEmpty {
                        VStack(spacing: 6) {
                            Spacer()
                            Image(systemName: "folder")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text("No files")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        LazyVStack(spacing: 6) {
                            ForEach(pointCloudManager.savedFiles) { file in
                                CompactFileRow(file: file) {
                                    pointCloudManager.deleteFile(file)
                                }
                            }
                        }
                    }
                }
                .padding() // 👈 Add padding here to avoid content touching edges
            }
        }
        .onAppear {
            // Update point count periodically
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                pointCloudManager.updatePointCount()
            }
            
            // Load saved files
            pointCloudManager.loadSavedFiles()
        }
    }
    
    private func startScanning() {
        Task {
            pointCloudManager.isScanning = true
            pointCloudManager.debugText = "Starting AR session..."
            await openImmersiveSpace(id: "SceneReconstruction")
        }
    }
    
    private func stopScanning() {
        Task {
            await dismissImmersiveSpace()
            pointCloudManager.isScanning = false
            pointCloudManager.debugText = "Scanning stopped. Ready to export data."
        }
    }
    
    private func getFileSize(url: URL) -> String? {
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

struct CompactFileRow: View {
    let file: SavedPointCloudFile
    let onDelete: () -> Void
    @State private var showingShareSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // File details
                VStack(alignment: .leading, spacing: 4) {
                    Text(shortenFileName(file.name))
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    
                    Text(formatDate(file.dateCreated ?? Date()))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("\(file.pointCount ?? 0) pts")
                        .font(.caption)
                }
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 2, y: 2)
        .hoverEffect(.highlight)
        .fileExporter(
            isPresented: $showingShareSheet,
            document: PLYDocument(url: file.url!),
            contentType: .ply,
            defaultFilename: file.name
        ) { result in
            switch result {
            case .success(let url):
                print("File exported to: \(url)")
            case .failure(let error):
                print("Export failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func shortenFileName(_ name: String) -> String {
        let components = name.components(separatedBy: "_")
        if components.count >= 3 {
            return components.dropFirst().joined(separator: "_").replacingOccurrences(of: ".ply", with: "")
        }
        return name.replacingOccurrences(of: ".ply", with: "")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }
}

// Document wrapper for file export
struct PLYDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.ply] }
    
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    init(configuration: ReadConfiguration) throws {
        // This won't be used for export-only documents
        fatalError("Reading not supported")
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return try FileWrapper(url: url)
    }
}

// UTType extension for PLY files
extension UTType {
    static var ply: UTType {
        UTType(importedAs: "com.example.ply")
    }
}

#Preview(windowStyle: .automatic) {
    MainView()
}
