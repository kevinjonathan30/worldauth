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
    @State private var showOnboarding = false
    @State var viewState: ViewState = .loading
    
    var body: some View {
        ARContainerView(viewState: $viewState)
            .onFinishRecording(authenticate(pointCloudData:))
            .navigationTitle("Authentication")
            .toolbar(.hidden)
            .edgesIgnoringSafeArea(.top)
            .onAppear {
                getPointCloudList()
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
                showOnboarding = data.isEmpty
            }
        }
    }
    
    private func authenticate(pointCloudData: [(position: SIMD3<Float>, color: UIColor)]) {
        self.viewState = .loading
        guard !pointCloudData.isEmpty else { return }
        let plyString = PointCloudHelper.createPlyString(from: pointCloudData)
        
        self.processPly(plyString: plyString)
    }
    
    private func processPly(plyString: String) {
        let targetData = Data(plyString.utf8)
        NetworkHelper.authenticatePointCloud(targetData) { data, error in
            if let error = error {
                print(error.localizedDescription)
                self.viewState = .loaded
            } else {
                guard let data = data else {
                    self.viewState = .loaded
                    return
                }
                
                DispatchQueue.main.async {
                    NavigationHelper.push(.successView(data.success ?? false, data.fitness ?? 0))
                    self.viewState = .loaded
                }
            }
        }
    }
}

#Preview {
    AuthenticationView()
}
