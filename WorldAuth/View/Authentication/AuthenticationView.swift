//
//  AuthenticationView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/03.
//

import ARKit
import SwiftUI
import SceneKit
import Combine

struct AuthenticationView: View {
    @State var session: ARSession
    @State var scene: SCNScene
    @State var pointColor = Color.white
    @State private var showPointCloud = false
    @State private var showMesh = true
    @State private var isViewActive = false
    @State private var fileList: [URL] = []
    @State private var showOnboarding = false
    @State private var similarityPercentage: Float = 0
    @State var isTakingPointCloud = false
    
    @EnvironmentObject var viewModel: AppViewModel
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init() {
        let session = ARSession()
        session.run(ARWorldHelper.getARWorldTrackingConfiguration(), options: ARWorldHelper.getARWorldTrackingOptions())
        self.session = session
        self.scene = SCNScene()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ARSceneView(
                session: self.$session,
                scene: self.$scene,
                pointColor: self.$pointColor,
                showPointCloud: self.$showPointCloud,
                showMesh: self.$showMesh
            )
            
            Text("\(similarityPercentage)%")
                .foregroundStyle(.white)
                .zIndex(999)
            
            takePointCloudButton()
        }
        .navigationTitle("Authentication")
        .onAppear {
            fileList = FileHelper.getFileList(atDirectory: "ply")
            guard !fileList.isEmpty else {
                showOnboarding = true
                return
            }
            isViewActive = true
        }
        .onDisappear {
            isViewActive = false
        }
        .onReceive(timer) { _ in
//            if isViewActive {
//                authenticate()
//            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
                .confirmAction {
                    showOnboarding = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NavigationHelper.push(.registerView)
                    }
                }
                .cancelAction {
                    showOnboarding = false
                }
                .environmentObject(viewModel)
        }
    }
}

// MARK: ViewBuilder

private extension AuthenticationView {
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
    
    private func getIconByTakePointCloudState() -> String {
        return isTakingPointCloud ? "stop.circle.fill" : "record.circle.fill"
    }
    
    private func handleTakePointCloudButtonEvent() {
        if isTakingPointCloud {
            isTakingPointCloud = false
            let recordStartSoundID: SystemSoundID = 1118
            AudioServicesPlaySystemSound(recordStartSoundID)
            authenticate()
        } else {
            isTakingPointCloud = true
            similarityPercentage = 0
            savePlyFile()
            let recordStartSoundID: SystemSoundID = 1117
            AudioServicesPlaySystemSound(recordStartSoundID)
        }
    }
}

// MARK: Handler

private extension AuthenticationView {
    private func savePlyFile() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !isTakingPointCloud {
                timer.invalidate()
            } else {
                // guard let pointCloud = self.session.currentFrame?.rawFeaturePoints else { return }
                guard let anchors = self.session.currentFrame?.anchors else { return }
                let meshAnchors = anchors.compactMap { $0 as? ARMeshAnchor }
                var pointsWithColor: [(position: SIMD3<Float>, color: UIColor)] = []
                for anchor in meshAnchors {
                    let vertices = PointCloudHelper.extractVertices(from: anchor.geometry)
                    pointsWithColor.append(contentsOf: vertices.map { (position: $0, color: UIColor(self.pointColor)) })
                }
                viewModel.pointCloudData = pointsWithColor
            }
        }
    }
    
    private func authenticate() {
        guard let anchors = self.session.currentFrame?.anchors else { return }
        let meshAnchors = anchors.compactMap { $0 as? ARMeshAnchor }
        
        var pointsWithColor: [(position: SIMD3<Float>, color: UIColor)] = []
        for anchor in meshAnchors {
            let vertices = PointCloudHelper.extractVertices(from: anchor.geometry)
            let coloredVertices = vertices.map { (position: $0, color: UIColor(self.pointColor)) }
            pointsWithColor.append(contentsOf: coloredVertices)
        }
        
        viewModel.pointCloudData.append(contentsOf: pointsWithColor)
        processAuthentication()
        
    }
    
    private func processAuthentication() {
        guard !viewModel.pointCloudData.isEmpty else { return }
        let plyString = PointCloudHelper.createPlyString(from: viewModel.pointCloudData)
        
        guard !fileList.isEmpty else { return }

        // Create a dispatch group
        let dispatchGroup = DispatchGroup()

        // Create a queue to manage sequential execution
        let queue = DispatchQueue(label: "jp.waseda.WorldAuthSequenceQueue")

        // Iterate over the file list
        for fileUrl in fileList {
            dispatchGroup.enter()
            queue.async {
//                self.processPlyOnline(savedPlyFileURL: fileUrl, plyString: plyString) {
//                    dispatchGroup.leave()
//                }
                self.processPly(savedPlyFileURL: fileUrl, plyString: plyString) {
                    dispatchGroup.leave()
                }
            }
            // Wait for the current task to finish before starting the next one
            dispatchGroup.wait()
        }
        
        viewModel.pointCloudData.removeAll()
    }
    
    private func processPly(savedPlyFileURL: URL, plyString: String, completion: @escaping () -> Void) {
        let similarity = PointCloudHelper.calculateSimilarity(savedPlyFileURL: savedPlyFileURL, currentPlyFileString: plyString)
        
        if similarity ?? 0 > similarityPercentage {
            similarityPercentage = similarity ?? 0
        }
        if similarity ?? 0 >= 80 {
            print("Similar!")
        } else {
            print("Not Similar!")
        }
        completion()
    }
    
    private func processPlyOnline(savedPlyFileURL: URL, plyString: String, completion: @escaping () -> Void) {
        guard let targetData = FileHelper.getDataByName(atDirectory: "ply", fileName: savedPlyFileURL.lastPathComponent) else {
            completion()
            return
        }
        let sourceData = Data(plyString.utf8)
        NetworkHelper.checkPlyData([targetData, sourceData]) { data, error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("Is User Authenticated: \(data)")
            }
            completion()
        }
    }
}

#Preview {
    AuthenticationView()
}
