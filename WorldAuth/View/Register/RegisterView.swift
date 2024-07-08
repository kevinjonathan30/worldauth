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
    @State var viewState: ViewState = .loaded
    
    var body: some View {
        ARContainerView(viewState: $viewState)
            .onFinishRecording(register(pointCloudData:))
            .navigationTitle("Register")
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityElement()
            .accessibilityLabel(Text("Register View", comment: "Accessibility label for Register view"))
            .accessibilityHint(Text("Register a new room template using AR", comment: "Accessibility hint for Register view"))
    }
}

// MARK: Handler

private extension RegisterView {
    private func register(pointCloudData: [(position: SIMD3<Float>, color: UIColor)]) {
        guard !pointCloudData.isEmpty else { return }
        viewState = .loading
        let plyString = PointCloudHelper.createPlyString(from: pointCloudData)
        
        NetworkHelper.registerPointCloud(Data(plyString.utf8)) { data, error in
            if let error = error {
                viewState = .loaded
                print(error.localizedDescription)
            } else {
                guard let data = data else {
                    viewState = .loaded
                    return
                }
                
                if data.success == true {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NavigationHelper.pop()
                        viewState = .loaded
                    }
                }
            }
        }
    }
}

#Preview {
    RegisterView()
}
