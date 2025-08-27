//
//  ResultView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/24.
//

import SwiftUI

struct ResultView: View {
    @Environment(\.dismiss) private var dismiss
    let success: Bool
    let similarity: Double
    @State private var isFinalState = false
    
    init(success: Bool = false, similarity: Double = 0) {
        self.success = success
        self.similarity = similarity
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: iconName)
                .font(.largeTitle)
                .modifier(SymbolTransitionModifier())
                .accessibilityElement()
                .accessibilityLabel(Text("Authentication Result Image"))
                .accessibilityHint(Text(success ? "Authenticated" : "Authentication Failed"))
                .accessibilityAddTraits([.isImage])
                .onAppear { isFinalState = true }
            
            Spacer()
            
            Text(success ? "Authentication Success" : "Authentication Failed")
                .font(.title2)
                .bold()
                .accessibilityElement()
                .accessibilityLabel(Text("Authentication Result Text"))
                .accessibilityHint(Text(success ? "Authentication Success" : "Authentication Failed"))
                .accessibilityAddTraits([.isStaticText])
            
            Text(success ? "Success! You’ve been authenticated." : "Authentication didn’t go through. Double-check and try again.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .accessibilityElement()
                .accessibilityLabel(Text("Result Description Text"))
                .accessibilityHint(Text(success ? "Success! You’ve been authenticated." : "Authentication didn’t go through. Double-check and try again."))
                .accessibilityAddTraits([.isStaticText])
            
            Spacer()
            
            backButton()
            
            Spacer()
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }
    
    private var iconName: String {
        if !isFinalState { return "lock.fill" }
        return success ? "lock.open.fill" : "lock.slash.fill"
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
                .accessibilityLabel(Text("Back to Home Button"))
                .accessibilityHint(Text("Return to Home Screen"))
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
