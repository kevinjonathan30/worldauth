//
//  RegisterView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/01.
//

import SwiftUI
import Combine
import AudioToolbox

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewState: ViewState = .loaded
    @State private var showAlert = false
    @State private var article = AlertArticle(title: "", description: "")
    
    var body: some View {
        ARContainerView(viewState: $viewState)
            .onFinishRecording(register(plyString:))
            .alert(article.title, isPresented: $showAlert, presenting: article) { _ in
                Button("Close", role: .cancel) {
                    showAlert = false
                }
            } message: { article in
                Text(article.description)
            }
            .navigationTitle("Register")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .accessibilityElement()
            .accessibilityLabel(Text("Register View", comment: "Accessibility label for Register view"))
            .accessibilityHint(Text("Register a new room template using AR", comment: "Accessibility hint for Register view"))
    }
}

// MARK: Handler

private extension RegisterView {
    private func register(plyString: String) {
        guard !plyString.isEmpty else { return }
        viewState = .loading
        
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
                        dismiss()
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
