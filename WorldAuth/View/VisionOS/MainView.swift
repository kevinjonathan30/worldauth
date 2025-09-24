//
//  MainView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/02/06.
//

import SwiftUI
import UniformTypeIdentifiers

struct MainView: View {
    @ObservedObject private var pointCloudManager = PointCloudManager.shared
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var isLoading: Bool = false // Loading state
    
    var body: some View {
        NavigationSplitView {
            HStack(spacing: 0) {
                // Main content (left side)
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
                    
                    if isLoading {
                        ProgressView("Processing...")
                            .padding()
                    } else {
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
                                        Text("Room template saved successfully!")
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
                            if !pointCloudManager.isScanning && pointCloudManager.pointCount == 0 {
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
                            } else if pointCloudManager.isScanning {
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
                            if !pointCloudManager.isScanning && pointCloudManager.pointCount > 0 {
                                VStack(spacing: 12) {
                                    // Authenticate button
                                    if !pointCloudManager.savedFiles.isEmpty {
                                        Button(action: authenticate) {
                                            HStack {
                                                Image(systemName: "camera.metering.center.weighted")
                                                Text("Authenticate")
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                        }
                                        .disabled(pointCloudManager.savedFiles.isEmpty)
                                    }
                                    
                                    // Save button
                                    Button(action: {
                                        isLoading = true
                                        pointCloudManager.exportPointCloud { _ in
                                            isLoading = false
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "square.and.arrow.up")
                                            Text("Save To My Template")
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
                                            Text("Reset Scanned Template")
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
                    }
                    
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
                        Text("My Room Templates")
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
            pointCloudManager.debugText = "Scanning stopped."
        }
    }
    
    private func authenticate() {
        Task {
            // Explicitly update the loading state on MainActor
            await MainActor.run {
                isLoading = true
            }

            let result = pointCloudManager.authenticatePointCloud()

            // Update UI state
            await MainActor.run {
                isLoading = false
                pointCloudManager.debugText = "Authentication accuracy result: \(result * 100)%."
            }
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
    @State private var showingDeleteConfirmation = false
    
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
                    
                    Text("\(file.pointCount ?? 0) pts (\(file.fileSize ?? "0 bytes"))")
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
                    
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
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
                print("File saved to: \(url)")
            case .failure(let error):
                print("Save failed: \(error.localizedDescription)")
            }
        }
        .alert("Delete this template?",
               isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
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
