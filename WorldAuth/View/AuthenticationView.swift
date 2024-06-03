//
//  AuthenticationView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/03.
//

import ARKit
import SwiftUI
import SceneKit
import AVFoundation
import ZIPFoundation
import Combine
import AudioToolbox

struct AuthenticationView: View {
    @State var session: ARSession
    @State var scene: SCNScene
    @State var pointColor = Color.white
    @State private var showPointCloud = true
    @State private var showMesh = false
    
    @StateObject var viewModel: AppViewModel = AppViewModel()
    
    init() {
        let session = ARSession()
        let configuration = ARWorldTrackingConfiguration()
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        session.run(configuration)
        self.session = session
        self.scene = SCNScene()
    }
    
    var body: some View {
        VStack {
            switch ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            case true:
                arView()
            case false:
                Text("Your device doesn't support LiDAR")
            }
        }
    }
}

// MARK: ViewBuilder

private extension AuthenticationView {
    @ViewBuilder
    private func arView() -> some View {
        ZStack(alignment: .bottom) {
            arSceneView()
            
            stutterView()
            
            takePointCloudButton()
        }
        .navigationTitle("WorldAuth")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                toolbarTrailingView()
            }
        }
    }
    
    @ViewBuilder
    private func arSceneView() -> some View {
        ARSceneView(
            session: self.$session,
            scene: self.$scene,
            pointColor: self.$pointColor,
            showPointCloud: self.$showPointCloud,
            showMesh: self.$showMesh
        )
        .edgesIgnoringSafeArea(.bottom)
    }
    
    @ViewBuilder
    private func stutterView() -> some View {
        Color.black
            .opacity(getStutterViewState())
            .animation(.easeInOut(duration: 0.1))
    }
    
    @ViewBuilder
    private func takePointCloudButton() -> some View {
        VStack {
            Button(action: { handleTakePointCloudButtonEvent() }) {
                Image(systemName: getIconByTakePointCloudState())
                    .foregroundColor(.red)
                    .font(.title)
                    .frame(width: 80, height: 80)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .padding()
        }
        .padding(.bottom, 20)
    }
    
    @ViewBuilder
    private func toolbarTrailingView() -> some View {
        Group {
            Button {
                calculateSimilarity()
                let recordStartSoundID: SystemSoundID = 1103
                AudioServicesPlaySystemSound(recordStartSoundID)
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .foregroundColor(.white)
            }
            
            Menu {
                Toggle(
                    isOn: $showPointCloud,
                    label: {
                        Label("Point", systemImage: "point.3.filled.connected.trianglepath.dotted")
                    }
                )
                
                Toggle(
                    isOn: $showMesh,
                    label: {
                        Label("Mesh", systemImage: "square.split.diagonal.2x2.fill")
                    }
                )
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    
}

// MARK: Helper

private extension AuthenticationView {
    private func getStutterViewState() -> Double {
        return viewModel.isScreenBlack ? 1 : 0
    }
    
    private func getIconByTakePointCloudState() -> String {
        return viewModel.isTakingPointCloud ? "stop.circle.fill" : "record.circle.fill"
    }
}

// MARK: Handler

private extension AuthenticationView {
    private func handleTakePointCloudButtonEvent() {
        if viewModel.isTakingPointCloud {
            viewModel.isTakingPointCloud = false
            viewModel.isScreenBlack = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.isScreenBlack = false
            }
            let recordStartSoundID: SystemSoundID = 1118
            AudioServicesPlaySystemSound(recordStartSoundID)
            captureImage()
        } else {
            viewModel.isTakingPointCloud = true
            savePlyFile()
            let recordStartSoundID: SystemSoundID = 1117
            AudioServicesPlaySystemSound(recordStartSoundID)
        }
    }
    
    private func createPlyString(from points: [(position: SIMD3<Float>, color: UIColor)]) -> String {
        let header = "ply\n" +
        "format ascii 1.0\n" +
        "element vertex \(points.count)\n" +
        "property float x\n" +
        "property float y\n" +
        "property float z\n" +
        "property uchar red\n" +
        "property uchar green\n" +
        "property uchar blue\n" +
        "end_header\n"
        
        var body = ""
        
        for point in points {
            let red = UInt8((point.color.cgColor.components?[0] ?? 0.0) * 255)
            let green = UInt8((point.color.cgColor.components?[1] ?? 0.0) * 255)
            let blue = UInt8((point.color.cgColor.components?[2] ?? 0.0) * 255)
            
            body += "\(point.position.x) \(point.position.y) \(point.position.z) \(red) \(green) \(blue)\n"
        }
        
        return header + body
    }
    
    private func savePlyFile() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !viewModel.isTakingPointCloud {
                timer.invalidate()
                guard !viewModel.pointCloudData.isEmpty else { return }
                let plyString = self.createPlyString(from: viewModel.pointCloudData)
                let dateString = viewModel.currentTimestamp ?? DateHelper.getStringFromDate()
                let fileName = "PointCloud_\(dateString).ply"
                let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
                
                do {
                    try plyString.write(to: fileURL, atomically: true, encoding: .utf8)
                    print("PLY file saved at: \(fileURL.path)")
                    self.viewModel.capturedPlyFileURLs.append(fileURL)
                } catch {
                    print("Error saving PLY file: \(error)")
                }
                viewModel.pointCloudData.removeAll()
            } else {
                guard let pointCloud = self.session.currentFrame?.rawFeaturePoints else { return }
                let pointsWithColor = pointCloud.points.map { (position: $0, color: UIColor(self.pointColor)) }
                viewModel.pointCloudData.append(contentsOf: pointsWithColor)
            }
        }
    }
    
    private func saveImage(_ image: UIImage) {
        let dateString = viewModel.currentTimestamp ?? DateHelper.getStringFromDate()
        let fileName = "Image_\(dateString).jpg"
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        
        if let data = image.jpegData(compressionQuality: 0.9) {
            do {
                try data.write(to: fileURL)
                print("Image saved at: \(fileURL.path)")
                self.viewModel.capturedImageURLs.append(fileURL)
            } catch {
                print("Error saving image: \(error)")
            }
        }
    }
    
    private func captureImage() {
        if let currentFrame = self.session.currentFrame {
            let image = CIImage(cvPixelBuffer: currentFrame.capturedImage)
            let context = CIContext()
            if let cgImage = context.createCGImage(image, from: image.extent) {
                let uiImage = UIImage(cgImage: cgImage)
                saveImage(uiImage)
            }
        }
    }
}

// MARK: Authenticator

private extension AuthenticationView {
    func parsePLYVertices(data: Data) -> [PLYVertex]? {
        guard let stringData = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        var vertices: [PLYVertex] = []
        var isHeaderFinished = false
        
        // Split lines
        let lines = stringData.components(separatedBy: .newlines)
        
        for line in lines {
            let components = line.components(separatedBy: .whitespaces)
            
            if components.count > 0 {
                if isHeaderFinished {
                    if let x = Float(components[0]), let y = Float(components[1]), let z = Float(components[2]) {
                        let vertex = PLYVertex(x: x, y: y, z: z)
                        vertices.append(vertex)
                    }
                } else {
                    if components[0] == "end_header" {
                        isHeaderFinished = true
                    }
                }
            }
        }
        
        return vertices
    }

    func computeHausdorffDistance(vertices1: [PLYVertex], vertices2: [PLYVertex]) -> Float {
        var maxDistance: Float = 0.0
        
        for vertex1 in vertices1 {
            var minDistance: Float = .greatestFiniteMagnitude
            
            for vertex2 in vertices2 {
                let distance = sqrt(pow(vertex1.x - vertex2.x, 2) + pow(vertex1.y - vertex2.y, 2) + pow(vertex1.z - vertex2.z, 2))
                if distance < minDistance {
                    minDistance = distance
                }
            }
            
            if minDistance > maxDistance {
                maxDistance = minDistance
            }
        }
        
        return maxDistance
    }
    
    func computeChamferDistance(vertices1: [PLYVertex], vertices2: [PLYVertex]) -> Float {
        var sumDistance1: Float = 0.0
        var sumDistance2: Float = 0.0
        
        // Compute the sum of squared distances from each point in vertices1 to the closest point in vertices2
        for vertex1 in vertices1 {
            var minDistance: Float = .greatestFiniteMagnitude
            
            for vertex2 in vertices2 {
                let distance = pow(vertex1.x - vertex2.x, 2) + pow(vertex1.y - vertex2.y, 2) + pow(vertex1.z - vertex2.z, 2)
                if distance < minDistance {
                    minDistance = distance
                }
            }
            
            sumDistance1 += minDistance
        }
        
        // Compute the sum of squared distances from each point in vertices2 to the closest point in vertices1
        for vertex2 in vertices2 {
            var minDistance: Float = .greatestFiniteMagnitude
            
            for vertex1 in vertices1 {
                let distance = pow(vertex1.x - vertex2.x, 2) + pow(vertex1.y - vertex2.y, 2) + pow(vertex1.z - vertex2.z, 2)
                if distance < minDistance {
                    minDistance = distance
                }
            }
            
            sumDistance2 += minDistance
        }
        
        // The Chamfer distance is the average of these two sums
        let chamferDistance = (sumDistance1 / Float(vertices1.count)) + (sumDistance2 / Float(vertices2.count))
        
        return chamferDistance
    }

    func normalizeDistance(_ distance: Float, maxThreshold: Float = 0.7) -> Float {
        return min(distance / maxThreshold, 1.0) // Ensure the normalized distance is capped at 1.0
    }

    func calculateSimilarity() {
        let file1URL: URL = viewModel.capturedPlyFileURLs[0]
        let file2URL: URL = viewModel.capturedPlyFileURLs[1]
        // Parse PLY files
        guard let file1Data = try? Data(contentsOf: file1URL),
              let file2Data = try? Data(contentsOf: file2URL),
              let file1Vertices = parsePLYVertices(data: file1Data),
              let file2Vertices = parsePLYVertices(data: file2Data) else { return }
        
        // Compute similarity metrics
            let hausdorffDistance1 = computeHausdorffDistance(vertices1: file1Vertices, vertices2: file2Vertices)
            let hausdorffDistance2 = computeHausdorffDistance(vertices1: file2Vertices, vertices2: file1Vertices)
            let hausdorffDistance = max(hausdorffDistance1, hausdorffDistance2)
            let chamferDistance = computeChamferDistance(vertices1: file1Vertices, vertices2: file2Vertices)
            
            // Normalize distances
            let normalizedHausdorff = normalizeDistance(hausdorffDistance)
            let normalizedChamfer = normalizeDistance(chamferDistance)
            
            // Convert to similarity percentage
            let hausdorffSimilarity = (1.0 - normalizedHausdorff) * 100.0
            let chamferSimilarity = (1.0 - normalizedChamfer) * 100.0
            
            // Print results
            print("Hausdorff Distance: \(hausdorffDistance), Similarity: \(hausdorffSimilarity)%")
            print("Chamfer Distance: \(chamferDistance), Similarity: \(chamferSimilarity)%")
            
            // Overall similarity (average of both metrics)
            let overallSimilarity = (hausdorffSimilarity + chamferSimilarity) / 2.0
            print("Overall Similarity: \(overallSimilarity)%")
    }
}

#Preview {
    AuthenticationView()
}
