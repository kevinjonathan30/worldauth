//
//  AuthenticationView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/03.
//

import ARKit
import SwiftUI
import Combine

struct AuthenticationView: View {
    @State private var showOnboarding = false
    @State var viewState: ViewState = .loading
    @State private var showAlert = false
    @State private var navigateToRegister: Bool = false
    @State private var navigateToResult: AuthenticationResult?
    @State private var article = AlertArticle(title: "", description: "")
    
    var body: some View {
        NavigationStack {
            VStack {
                ARContainerView(viewState: $viewState)
                    .onFinishRecording(authenticate(plyString:))
                    .navigationTitle("WorldAuth")
                    .navigationBarTitleDisplayMode(.inline)
                    .onAppear {
                        getPointCloudList()
                    }
                    .accessibilityElement()
                    .accessibilityLabel(Text("Augmented Reality Container", comment: "Accessibility label for the AR container view"))
                    .accessibilityHint(Text("Displays the AR content for authentication", comment: "Accessibility hint for the AR container view"))
                    .sheet(isPresented: $showOnboarding) {
                        OnboardingView()
                            .confirmAction {
                                showOnboarding = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    navigateToRegister = true
                                }
                            }
                            .accessibilityElement()
                            .accessibilityLabel(Text("Onboarding View", comment: "Accessibility label for the onboarding view"))
                            .accessibilityHint(Text("Displays onboarding instructions", comment: "Accessibility hint for the onboarding view"))
                    }
                    .alert(article.title, isPresented: $showAlert, presenting: article) { _ in
                        Button("Close", role: .cancel) {
                            showAlert = false
                        }
                    } message: { article in
                        Text(article.description)
                    }
                
                NavigationLink(value: "Register") {
                    EmptyView()
                }
                .navigationDestination(for: String.self) { _ in
                    RegisterView()
                        .accessibilityElement()
                        .accessibilityLabel(Text("Register View", comment: "Accessibility label for register view"))
                        .accessibilityHint(Text("View to register new users", comment: "Accessibility hint for register view"))
                }

                NavigationLink(value: "Result") {
                    EmptyView()
                }
                .navigationDestination(for: String.self) { _ in
                    ResultView(success: navigateToResult?.success ?? false, similarity: navigateToResult?.fitness ?? 0)
                        .accessibilityElement()
                        .accessibilityLabel(Text("Result View", comment: "Accessibility label for result view"))
                        .accessibilityHint(Text("View showing registration results", comment: "Accessibility hint for result view"))
                }
            }
            .navigationDestination(isPresented: $navigateToRegister) {
                RegisterView()
                    .accessibilityElement()
                    .accessibilityLabel(Text("Register View", comment: "Accessibility label for register view"))
                    .accessibilityHint(Text("View to register new users", comment: "Accessibility hint for register view"))
            }
            .navigationDestination(isPresented: Binding(
                get: { navigateToResult != nil },
                set: { isActive in
                    if !isActive {
                        navigateToResult = nil
                    }
                }
            )) {
                ResultView(success: navigateToResult?.success ?? false, similarity: navigateToResult?.fitness ?? 0)
                    .accessibilityElement()
                    .accessibilityLabel(Text("Result View", comment: "Accessibility label for result view"))
                    .accessibilityHint(Text("View showing registration results", comment: "Accessibility hint for result view"))
            }
        }
    }
}

// MARK: Handler

private extension AuthenticationView {
    private func getPointCloudList() {
        viewState = .loading
        if RemoteConfigProvider.shared.prefersOnDevice() {
            let data = FileHelper.getFileList()
            self.viewState = .loaded
            showOnboarding = data.isEmpty
        } else {
            NetworkHelper.getPointCloud { data, error in
                if let error = error {
                    article = AlertArticle(title: "An Error Occurred", description: error.localizedDescription)
                    showAlert = true
                    viewState = .fail
                } else {
                    guard let data = data else {
                        viewState = .fail
                        return
                    }
                    self.viewState = .loaded
                    showOnboarding = data.isEmpty
                }
            }
        }
    }
    
    private func authenticate(plyString: String) {
        self.viewState = .loading
        guard !plyString.isEmpty else { return }
        
        self.processPly(plyString: plyString)
    }
    
    private func processPly(plyString: String) {
        if RemoteConfigProvider.shared.prefersOnDevice() {
            processPlyOnDevice(plyString: plyString)
            return
        }
        
        processPlyOnline(plyString: plyString)
    }
    
    private func processPlyOnDevice(plyString: String) {
        var highestResult: Double = 0
        for file in FileHelper.getFileList() {
            let targetString = FileHelper.getDataStringByName(fileName: file.lastPathComponent)
            let result = AuthenticationHelper.runInference(source: plyString, target: targetString)
            highestResult = result > highestResult ? result : highestResult
        }
        navigateToResult = AuthenticationResult(error: nil, success: highestResult == 1, fitness: highestResult)
        self.viewState = .loaded
    }
    
    private func processPlyOnline(plyString: String) {
        let targetData = Data(plyString.utf8)
        
        NetworkHelper.authenticatePointCloud(targetData) { data, error in
            if let error = error {
                article = AlertArticle(title: "An Error Occurred", description: error.localizedDescription)
                showAlert = true
                self.viewState = .loaded
            } else {
                guard let data = data else {
                    self.viewState = .loaded
                    return
                }
                
                DispatchQueue.main.async {
                    navigateToResult = AuthenticationResult(error: nil, success: data.fitness == 1, fitness: data.fitness ?? 0)
                    self.viewState = .loaded
                }
            }
        }
    }
}

#Preview {
    AuthenticationView()
}
