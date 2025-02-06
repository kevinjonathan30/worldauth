//
//  ResultView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/24.
//

import SwiftUI
import FirebaseRemoteConfig

struct ResultView: View {
    @Environment(\.dismiss) private var dismiss
    let success: Bool
    let similarity: Double
    @State private var selectedMethod = "-"
    
    init(success: Bool = false, similarity: Double = 0) {
        self.success = success
        self.similarity = similarity
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: success ? "lock.open.fill" : "lock.slash.fill")
                .font(.largeTitle)
                .accessibilityElement()
                .accessibilityLabel(Text("Authentication Result Image", comment: "Accessibility label for image"))
                .accessibilityHint(Text(success ? "Authenticated" : "Authentication Failed", comment: "Accessibility hint for image"))
                .accessibilityAddTraits([.isImage])
            
            Spacer()
            
            Text(success ? "Authentication Success" : "Authentication Failed")
                .font(.title2)
                .bold()
                .accessibilityElement()
                .accessibilityLabel(Text("Authentication Result Text", comment: "Accessibility label for text"))
                .accessibilityHint(Text(success ? "Authentication Success" : "Authentication Failed", comment: "Accessibility hint for text"))
                .accessibilityAddTraits([.isStaticText])
            
            Text(String(format: "Similarity: %.2f%%", similarity * 100))
                .accessibilityElement()
                .accessibilityLabel(Text("Similarity to Room Template Text", comment: "Accessibility label for text"))
                .accessibilityHint(Text("The similarity of the scanned room compared to the saved room template is \(String(format: "Similarity: %.2f%%", similarity * 100))", comment: "Accessibility hint for text"))
                .accessibilityAddTraits([.isStaticText])
            
            Text("Auth Method: \(selectedMethod)")
                .accessibilityElement()
                .accessibilityLabel(Text("Authentication Method", comment: "Accessibility label for text"))
                .accessibilityHint(Text("The authentication method used is \(selectedMethod)", comment: "Accessibility hint for text"))
                .accessibilityAddTraits([.isStaticText])
            
            Spacer()
            
            backButton()
            
            Spacer()
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task {
            Task {
                try await startFetching()
            }
        }
    }
}

private extension ResultView {
    @ViewBuilder func backButton() -> some View {
        Button {
            dismiss()
        } label: {
            Text("Back to Home")
                .bold()
                .foregroundColor(.white)
                .padding()
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.accentColor)
                        .clipShape(Capsule())
                )
                .accessibilityElement()
                .accessibilityLabel(Text("Back to Home Button", comment: "Accessibility label for button"))
                .accessibilityHint(Text("Return to Home Screen", comment: "Accessibility hint for button"))
                .accessibilityAddTraits([.isButton])
        }
        .transaction { transaction in
            transaction.animation = .none
        }
    }
}

private extension ResultView {
    private func startFetching() async throws {
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
        
        do {
            let config = try await remoteConfig.fetchAndActivate()
            switch config {
            case .successFetchedFromRemote:
                self.selectedMethod = remoteConfig.configValue(forKey: "authentication_method").stringValue
                return
            case .successUsingPreFetchedData:
                self.selectedMethod = remoteConfig.configValue(forKey: "authentication_method").stringValue
                return
            default:
                print("Error activating")
                return
            }
        } catch let error {
            print("Error fetching: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ResultView(success: true, similarity: 1.0)
}
