//
//  RegisterView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/01.
//

import ARKit
import SwiftUI
import SceneKit
import Combine
import AudioToolbox

struct RegisterView: View {
    @State var session: ARSession = ARSession()
    @State var scene: SCNScene = SCNScene()
    @State private var showMesh = true
    @State private var isIdealDistance: DistanceState = .normal
    @State var isTakingPointCloud = false
    @State var isScreenBlack = false
    @State var pointCloudData: [(position: SIMD3<Float>, color: UIColor)] = []
    
    var body: some View {
        ZStack {
            distanceIndicator()
            
            arSceneView()
            
            stutterView()
            
            takePointCloudButton()
        }
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let session = ARSession()
            session.run(ARWorldHelper.getARWorldTrackingConfiguration(), options: ARWorldHelper.getARWorldTrackingOptions())
            self.session = session
        }
        .onDisappear {
            self.session.pause()
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
            showMesh: self.$showMesh,
            isIdealDistance: self.$isIdealDistance
        )
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
            Spacer()
            
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
        .transaction { transaction in
            transaction.animation = .none
        }
    }
    
    @ViewBuilder
    private func distanceIndicator() -> some View {
        VStack {
            Text(getDistanceState())
                .foregroundStyle(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .opacity(isIdealDistance == .normal ? 0 : 0.75)
                        .zIndex(999)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 8)
                        )
                )
                .padding()
            
            Spacer()
        }
        .padding(.top, 32)
        .animation(.bouncy, value: isIdealDistance)
        .zIndex(999)
    }
    
    private func getDistanceState() -> String {
        switch isIdealDistance {
        case .normal:
            return ""
        case .close:
            return "Your device is too close to the environment, please step farther."
        case .far:
            return "Your device is too far from the environment, please step closer."
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
                guard !pointCloudData.isEmpty else { return }
                let plyString = PointCloudHelper.createPlyString(from: pointCloudData)
                
                NetworkHelper.registerPointCloud(Data(plyString.utf8)) { data, error in
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        guard let data = data else { return }
                        if data.success == true {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                NavigationHelper.pop()
                            }
                        }
                    }
                }
                
                pointCloudData.removeAll()
            } else {
                guard let anchors = self.session.currentFrame?.anchors else { return }
                let meshAnchors = anchors.compactMap { $0 as? ARMeshAnchor }
                var pointsWithColor: [(position: SIMD3<Float>, color: UIColor)] = []
                for anchor in meshAnchors {
                    let vertices = PointCloudHelper.extractVertices(from: anchor.geometry)
                    pointsWithColor.append(contentsOf: vertices.map { (position: $0, color: UIColor(Color.white)) })
                }
                pointCloudData = pointsWithColor
            }
        }
    }
    
    private func saveImage(_ image: UIImage) {
        if let _ = image.jpegData(compressionQuality: 0.9) {  }
    }
    
    private func captureImage() {
        if let currentFrame = self.session.currentFrame {
            let image = CIImage(cvPixelBuffer: currentFrame.capturedImage)
            let context = CIContext()
            if let cgImage = context.createCGImage(image, from: image.extent) {
                var uiImage = UIImage(cgImage: cgImage)
                
                // Check if the image orientation is landscape
                if uiImage.size.width > uiImage.size.height {
                    // Rotate the image to portrait orientation
                    uiImage = uiImage.rotate(radians: .pi / 2)!
                }
                
                saveImage(uiImage)
            }
        }
    }
}

#Preview {
    RegisterView()
}
