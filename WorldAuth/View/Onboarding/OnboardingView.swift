//
//  OnboardingView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/08.
//

import SwiftUI

struct OnboardingView: View {
    var confirmAction: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            
            Text("No Registered Room Template")
                .multilineTextAlignment(.center)
                .font(.largeTitle)
                .bold()
                .padding(.bottom)
                .accessibilityElement()
                .accessibilityLabel(Text("No Registered Room Template", comment: "Accessibility label for text"))
                .accessibilityHint(Text("You don't have registered room needed for authentication", comment: "Accessibility hint for text"))
                .accessibilityAddTraits([.isStaticText])
            
            Text("To use WorldAuth, please register your room template for authentication purpose.")
                .multilineTextAlignment(.center)
                .accessibilityElement()
                .accessibilityLabel(Text("Register Your Room Template", comment: "Accessibility label for text"))
                .accessibilityHint(Text("Please register your room template for authentication", comment: "Accessibility hint for text"))
                .accessibilityAddTraits([.isStaticText])
            
            Spacer()
            
            Button {
                confirmAction?()
            } label: {
                Text("Register")
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
            .accessibilityElement()
            .accessibilityLabel(Text("Register Button", comment: "Accessibility label for button"))
            .accessibilityHint(Text("Register Room Template", comment: "Accessibility hint for button"))
            .accessibilityAddTraits([.isButton])
            
            Spacer()
        }
        .padding()
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled(true)
    }
}

// MARK: Public Modifier

extension OnboardingView {
    
    /// confirmAction
    /// - Parameter action: runs an action everytime the button is tapped
    /// - Returns: OnboardingView
    func confirmAction(_ confirmAction: @escaping(() -> Void)) -> Self {
        var copy = self
        copy.confirmAction = confirmAction
        return copy
    }
}

#Preview {
    OnboardingView()
}
