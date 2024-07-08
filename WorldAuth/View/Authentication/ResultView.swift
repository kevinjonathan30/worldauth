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
                .accessibilityLabel(Text("Authentication result image", comment: "Accessibility label for image"))
                .accessibilityHint(Text("\(success ? "Authentication Success" : "Authentication Failed")", comment: "Accessibility hint for image"))
                .accessibilityAddTraits([.isImage])
            
            Spacer()
            
            Text(success ? "Authentication Success" : "Authentication Failed")
                .font(.title2)
                .bold()
                .accessibilityLabel(Text("Similarity to room template matching result text", comment: "Accessibility label for text"))
                .accessibilityHint(Text("\(success ? "Authentication Success" : "Authentication Failed")", comment: "Accessibility hint for text"))
                .accessibilityAddTraits([.isStaticText])
            
            Text("Similarity: \(similarity * 100)%")
                .accessibilityLabel(Text("Similarity to room template text", comment: "Accessibility label for text"))
                .accessibilityHint(Text("The similarity of the scanned room compared to the saved room template is \(similarity * 100)", comment: "Accessibility hint for text"))
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
                        .background(.accent)
                        .clipShape(Capsule())
                )
        }
        .transaction { transaction in
            transaction.animation = .none
        }
        .accessibilityLabel(Text("Back to Home Button", comment: "Accessibility label for button"))
        .accessibilityHint(Text("Back To Home", comment: "Accessibility hint for button"))
        .accessibilityAddTraits([.isButton])
    }
}

#Preview {
    ResultView(success: true, similarity: 1.0)
}
