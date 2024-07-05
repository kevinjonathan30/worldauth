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
            
            Text("To use WorldAuth, please register your room template for authentication purpose.")
                .multilineTextAlignment(.center)
            
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
