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
    @State private var showMesh = true
    @State private var isIdealDistance: DistanceState = .normal
    @State private var showOnboarding = false
    @State var isTakingPointCloud = false
    @State var pointCloudData: [(position: SIMD3<Float>, color: UIColor)] = []
    @State var viewState: ViewState = .loading
    @State var pointCloudList: [WorldTemplate] = []
    
    var body: some View {
        ZStack {
            distanceIndicator()
            
            ARSceneView(
                session: self.$session,
                scene: self.$scene,
                showMesh: self.$showMesh,
                isIdealDistance: self.$isIdealDistance
            )
            
            stutterView()
            
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
                .cancelAction {
                    showOnboarding = false
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
    }
    
    @ViewBuilder
    private func distanceIndicator() -> some View {
        if viewState != .loading {
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
    }
    
    @ViewBuilder
    private func stutterView() -> some View {
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
