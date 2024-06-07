//
//  RegisterView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/01.
//

import ARKit
import SwiftUI
import SceneKit
import ZIPFoundation
import Combine
import AudioToolbox

struct RegisterView: View {
    @State var session: ARSession
    @State var scene: SCNScene
    @State var pointColor = Color.white
    @State private var showPointCloud = true
    @State private var showMesh = false
    
    @State var isTakingPointCloud = false
    @State var isScreenBlack = false
    
    @EnvironmentObject var viewModel: AppViewModel
    
    init() {
        let session = ARSession()
        session.run(ARWorldHelper.getARWorldTrackingConfiguration(), options: [.resetTracking,.removeExistingAnchors,.stopTrackedRaycasts])
        self.session = session
        self.scene = SCNScene()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            arSceneView()
            
            stutterView()
            
            takePointCloudButton()
        }
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                toolbarTrailingView()
            }
        }
    }
}

// MARK: ViewBuilder

private extension RegisterView {
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
        return isScreenBlack ? 1 : 0
    }
    
    private func getIconByTakePointCloudState() -> String {
        return isTakingPointCloud ? "stop.circle.fill" : "record.circle.fill"
    }
}

// MARK: Handler

private extension RegisterView {
    private func handleTakePointCloudButtonEvent() {
        if isTakingPointCloud {
            isTakingPointCloud = false
            isScreenBlack = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isScreenBlack = false
            }
            let recordStartSoundID: SystemSoundID = 1118
            AudioServicesPlaySystemSound(recordStartSoundID)
            captureImage()
        } else {
            isTakingPointCloud = true
            savePlyFile()
            let recordStartSoundID: SystemSoundID = 1117
            AudioServicesPlaySystemSound(recordStartSoundID)
        }
    }
    
    private func savePlyFile() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !isTakingPointCloud {
                timer.invalidate()
                guard !viewModel.pointCloudData.isEmpty else { return }
                let plyString = PointCloudHelper.createPlyString(from: viewModel.pointCloudData)
                let dateString = viewModel.currentTimestamp ?? DateHelper.getStringFromDate()
                let fileName = "PointCloud_\(dateString).ply"
                
                if let fileURL = FileHelper.saveFile(data: Data(plyString.utf8), atDirectory: "ply", fileName: fileName) {
                    self.viewModel.capturedPlyFileURLs.append(fileURL)
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
        
        if let data = image.jpegData(compressionQuality: 0.9),
           let fileURL = FileHelper.saveFile(data: data, atDirectory: "img", fileName: fileName) {
            self.viewModel.capturedImageURLs.append(fileURL)
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
        
        // Disable point cloud and mesh state everytime user tries to share, and revert it later
        viewModel.showPointCloudTemp = showPointCloud
        showPointCloud = false
        viewModel.showMeshTemp = showMesh
        showMesh = false
        
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
            print(error.localizedDescription)
        }
    }
}

#Preview {
    RegisterView()
}
