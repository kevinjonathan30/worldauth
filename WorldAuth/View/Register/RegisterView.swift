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
    @State private var showAlert = false
    @State private var article = AlertArticle(title: "", description: "")
    
    var body: some View {
        ARContainerView(viewState: $viewState)
            .onFinishRecording(register(pointCloudData:))
            .alert(article.title, isPresented: $showAlert, presenting: article) { _ in
                Button("Close", role: .cancel) {
                    showAlert = false
                }
            } message: { article in
                Text(article.description)
            }
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
                article = AlertArticle(title: "An Error Occured", description: error.localizedDescription)
                showAlert = true
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
                } else {
                    viewState = .loaded
                    print(data.error ?? "")
                }
            }
        }
    }
}

#Preview {
    RegisterView()
}
