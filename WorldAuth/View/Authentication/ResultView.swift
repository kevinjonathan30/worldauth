//
//  ResultView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/24.
//

import SwiftUI

struct ResultView: View {
    let success: Bool
    let similarity: Double
    
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
                .accessibilityHint(Text(success ? "Authentication Success" : "Authentication Failed", comment: "Accessibility hint for image"))
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
            
            Spacer()
            
            backButton()
            
            Spacer()
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }
}

private extension ResultView {
    @ViewBuilder func backButton() -> some View {
        Button {
            NavigationHelper.pop()
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

#Preview {
    ResultView(success: true, similarity: 1.0)
}
