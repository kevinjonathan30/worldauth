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
    @State var session: ARSession = ARSession()
    @State var scene: SCNScene = SCNScene()
    @State private var isIdealDistance: DistanceState = .normal
    @State private var showOnboarding = false
    @State var isTakingPointCloud = false
    @State var pointCloudData: [(position: SIMD3<Float>, color: UIColor)] = []
    @State var viewState: ViewState = .loading
    @State var pointCloudList: [WorldTemplate] = []
    
    var body: some View {
        ZStack {
            DistanceToasterView(isIdealDistance: $isIdealDistance)
                .zIndex(999)
            
            ARSceneView(
                session: self.$session,
                scene: self.$scene,
                isIdealDistance: self.$isIdealDistance
            )
            
            loadingView()
            
            takePointCloudButton()
        }
        .navigationTitle("Authentication")
        .toolbar(.hidden)
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            let session = ARSession()
            session.run(ARWorldHelper.getARWorldTrackingConfiguration(), options: ARWorldHelper.getARWorldTrackingOptions())
            self.session = session
            getPointCloudList()
        }
        .onDisappear {
            self.session.pause()
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
                .confirmAction {
                    showOnboarding = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NavigationHelper.push(.registerView)
                    }
                }
        }
    }
}

// MARK: ViewBuilder

private extension AuthenticationView {
    @ViewBuilder
    private func takePointCloudButton() -> some View {
        if viewState != .loading && !pointCloudList.isEmpty {
            VStack {
                Spacer()
                
                Button(action: handleTakePointCloudButtonEvent) {
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
    }
    
    @ViewBuilder
    private func loadingView() -> some View {
        ZStack {
            Color.white
                
            ProgressView()
                .zIndex(999)
        }
        .opacity(getStutterViewState())
        .animation(.easeInOut(duration: 0.1), value: viewState)
    }
    
    private func getIconByTakePointCloudState() -> String {
        return isTakingPointCloud ? "stop.circle.fill" : "record.circle.fill"
    }
    
    private func getStutterViewState() -> Double {
        return viewState == .loading ? 1 : 0
    }
    
    private func handleTakePointCloudButtonEvent() {
        if isTakingPointCloud {
            isTakingPointCloud = false
            let recordStartSoundID: SystemSoundID = 1118
            AudioServicesPlaySystemSound(recordStartSoundID)
            authenticate()
        } else {
            isTakingPointCloud = true
            savePlyFile()
            let recordStartSoundID: SystemSoundID = 1117
            AudioServicesPlaySystemSound(recordStartSoundID)
        }
    }
}

// MARK: Handler

private extension AuthenticationView {
    private func getPointCloudList() {
        viewState = .loading
        NetworkHelper.getPointCloud { data, error in
            if let error = error {
                print(error.localizedDescription)
                viewState = .fail
            } else {
                guard let data = data else { return }
                self.viewState = .loaded
                pointCloudList = data
                showOnboarding = data.isEmpty
            }
        }
    }
    
    private func savePlyFile() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !isTakingPointCloud {
                timer.invalidate()
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
    
    private func authenticate() {
        guard let anchors = self.session.currentFrame?.anchors else { return }
        self.viewState = .loading
        let meshAnchors = anchors.compactMap { $0 as? ARMeshAnchor }
        
        var pointsWithColor: [(position: SIMD3<Float>, color: UIColor)] = []
        for anchor in meshAnchors {
            let vertices = PointCloudHelper.extractVertices(from: anchor.geometry)
            let coloredVertices = vertices.map { (position: $0, color: UIColor(Color.white)) }
            pointsWithColor.append(contentsOf: coloredVertices)
        }
        
        pointCloudData.append(contentsOf: pointsWithColor)
        processAuthentication()
    }
    
    private func processAuthentication() {
        guard !pointCloudData.isEmpty else { return }
        let plyString = PointCloudHelper.createPlyString(from: pointCloudData)
        
        self.processPly(plyString: plyString)
        
        pointCloudData.removeAll()
    }
    
    private func processPly(plyString: String) {
        let targetData = Data(plyString.utf8)
        NetworkHelper.authenticatePointCloud(targetData) { data, error in
            if let error = error {
                print(error.localizedDescription)
                self.viewState = .loaded
            } else {
                guard let data = data else { return }
                
                DispatchQueue.main.async {
                    NavigationHelper.push(.successView(data.success ?? false, data.fitness ?? 0))
                }
            }
        }
    }
}

#Preview {
    AuthenticationView()
}
