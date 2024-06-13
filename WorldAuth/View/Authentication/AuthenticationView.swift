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
    @State private var showPointCloud = true
    @State private var showMesh = false
    @State private var isViewActive = false
    @State private var fileList: [URL] = []
    @State private var showOnboarding = false
    @State private var similarityPercentage: String = "0%"
    
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
            
            Text(similarityPercentage)
                .foregroundStyle(.white)
                .zIndex(999)
        }
        .navigationTitle("Authentication")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                toolbarTrailingView()
            }
        }
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
            if isViewActive {
                authenticate()
            }
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
            if isViewActive {
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
}

// MARK: Handler

private extension AuthenticationView {
    private func authenticate() { // TODO: Handle if range is farther than 5 meters (Hint: lidar point clouds are 576)
//        guard let pointCloud = self.session.currentFrame?.rawFeaturePoints else { return }
//        let pointsWithColor = pointCloud.points.map { (position: $0, color: UIColor(self.pointColor)) }
        
        guard let anchors = self.session.currentFrame?.anchors else { return }
        let meshAnchors = anchors.compactMap { $0 as? ARMeshAnchor }
        var pointsWithColor: [(position: SIMD3<Float>, color: UIColor)] = []

        // Process all anchors on a background queue
        DispatchQueue.global(qos: .userInitiated).async {
            for anchor in meshAnchors {
                let vertices = PointCloudHelper.extractVertices(from: anchor.geometry)
                let coloredVertices = vertices.map { (position: $0, color: UIColor(self.pointColor)) }
                pointsWithColor.append(contentsOf: coloredVertices)
            }
            
            // Append processed data to viewModel on the main queue
            DispatchQueue.main.async {
                viewModel.pointCloudData.append(contentsOf: pointsWithColor)
                processAuthentication() // Ensure this method handles UI updates safely
            }
        }
    }
    
    private func processAuthentication() {
        guard !viewModel.pointCloudData.isEmpty else { return }
        let plyString = PointCloudHelper.createPlyString(from: viewModel.pointCloudData)
        
        guard !fileList.isEmpty else { return }
        
        for fileUrl in fileList {
            processPly(savedPlyFileURL: fileUrl, plyString: plyString)
        }
    }
    
    private func processPly(savedPlyFileURL: URL, plyString: String) {
        let similarity = PointCloudHelper.calculateSimilarity(savedPlyFileURL: savedPlyFileURL, currentPlyFileString: plyString)
        similarityPercentage = "\(similarity ?? 0)%"
        
        // TODO: Handle if success, ignore if nothing happens
        DispatchQueue.main.async {
            if similarity ?? 0 >= 80 { // TODO: Reconsider similarity percentage for auth
                print("Similar!")
            } else {
                print("Not Similar!")
            }
            viewModel.pointCloudData.removeAll()
        }
    }
}

#Preview {
    AuthenticationView()
}
