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
    
    @EnvironmentObject var viewModel: AppViewModel
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init() {
        let session = ARSession()
        session.run(ARWorldHelper.getARWorldTrackingConfiguration(), options: [.resetTracking,.removeExistingAnchors,.stopTrackedRaycasts])
        self.session = session
        self.scene = SCNScene()
    }
    
    var body: some View {
        ARSceneView(
            session: self.$session,
            scene: self.$scene,
            pointColor: self.$pointColor,
            showPointCloud: self.$showPointCloud,
            showMesh: self.$showMesh
        )
        .navigationTitle("Authentication")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                toolbarTrailingView()
            }
        }
        .onAppear {
            fileList = []
            isViewActive = true
        }
        .onDisappear {
            isViewActive = false
        }
        .onReceive(timer) { _ in
            if isViewActive {
                updatePlyFile()
            }
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
    private func updatePlyFile() {
        guard let pointCloud = self.session.currentFrame?.rawFeaturePoints else { return }
        let pointsWithColor = pointCloud.points.map { (position: $0, color: UIColor(self.pointColor)) }
        
        DispatchQueue.global(qos: .userInitiated).async {
            viewModel.pointCloudData.append(contentsOf: pointsWithColor)
            processPly()
        }
    }
    
    private func processPly() {
        guard !viewModel.pointCloudData.isEmpty else { return }
        let plyString = PointCloudHelper.createPlyString(from: viewModel.pointCloudData)
        
        fileList = fileList.isEmpty ? FileHelper.getFileList(atDirectory: "ply") : fileList
        guard !fileList.isEmpty else { return }
        
        let similarity = PointCloudHelper.calculateSimilarity(savedPlyFileURL: fileList[0], currentPlyFileString: plyString)
        print(similarity ?? "")
        
        DispatchQueue.main.async {
            if similarity ?? 0 >= 80 {
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
