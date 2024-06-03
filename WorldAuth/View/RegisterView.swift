//
//  RegisterView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/01.
//

import ARKit
import SwiftUI
import SceneKit
import AVFoundation
import ZIPFoundation
import Combine
import AudioToolbox

struct RegisterView: View {
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

private extension RegisterView {
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
                shareFiles()
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

private extension RegisterView {
    private func getStutterViewState() -> Double {
        return viewModel.isScreenBlack ? 1 : 0
    }
    
    private func getIconByTakePointCloudState() -> String {
        return viewModel.isTakingPointCloud ? "stop.circle.fill" : "record.circle.fill"
    }
}

// MARK: Handler

private extension RegisterView {
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
    
    private func shareFiles() {
        guard !viewModel.capturedPlyFileURLs.isEmpty, !viewModel.capturedImageURLs.isEmpty else {
            print("No PLY or JPG files found")
            return
        }
        
        let fileManager = FileManager.default
        let dateString = DateHelper.getStringFromDate()
        let zipFileName = "PointCloud_\(dateString).zip"
        let documentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let zipFileURL = documentsDirectoryURL.appendingPathComponent(zipFileName)
        
        do {
            let archive = try Archive(url: zipFileURL, accessMode: .create)
            for plyFileURL in viewModel.capturedPlyFileURLs {
                try archive.addEntry(with: plyFileURL.lastPathComponent, relativeTo: documentsDirectoryURL)
            }
            for imageFileURL in viewModel.capturedImageURLs {
                try archive.addEntry(with: imageFileURL.lastPathComponent, relativeTo: documentsDirectoryURL)
            }
            
            // Disable point cloud and mesh state everytime user tries to share, and revert it later
            viewModel.showPointCloudTemp = showPointCloud
            showPointCloud = false
            viewModel.showMeshTemp = showMesh
            showMesh = false
            
            DispatchQueue.main.async {
                let activityViewController = UIActivityViewController(activityItems: [zipFileURL], applicationActivities: nil)
                activityViewController.completionWithItemsHandler =  { _, _, _, _ in
                    showPointCloud = viewModel.showPointCloudTemp
                    showMesh = viewModel.showMeshTemp
                }
                if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                    scene.windows.first?.rootViewController?.present(
                        activityViewController,
                        animated: true,
                        completion: nil
                    )
                }
            }
            
        } catch {
            print("Error sharing files: \(error)")
        }
    }
}

#Preview {
    RegisterView()
}
