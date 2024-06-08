//
//  OnboardingView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/08.
//

import SwiftUI

struct OnboardingView: View {
    var confirmAction: (() -> Void)?
    var cancelAction: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            
            Text("No Registered Point Cloud")
                .multilineTextAlignment(.center)
                .font(.largeTitle)
                .bold()
            
            Text("To use WorldAuth, you must register your point cloud first for authentication purpose. Do you want to register it now?")
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button {
                confirmAction?()
            } label: {
                Text("Register")
            }
            
            Spacer()
            
            Button {
                cancelAction?()
            } label: {
                Text("Later")
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
    
    /// cancelAction
    /// - Parameter cancelAction: runs an action everytime the button is tapped
    /// - Returns: OnboardingView
    func cancelAction(_ cancelAction: @escaping(() -> Void)) -> Self {
        var copy = self
        copy.cancelAction = cancelAction
        return copy
    }
}

#Preview {
    OnboardingView()
}
