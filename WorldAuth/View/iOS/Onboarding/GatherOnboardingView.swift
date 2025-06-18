//
//  GatherOnboardingView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/06/17.
//

import SwiftUI

struct GatherOnboardingView: View {
    var confirmAction: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .center) {
            VStack {
                Spacer()
                
                Text("WorldAuth")
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
                
                featureListView()
                
                Spacer()
                
                Button {
                    confirmAction?()
                } label: {
                    Text("Continue")
                        .foregroundColor(.white)
                        .bold()
                        .padding()
                        .background(
                            Capsule(style: .continuous)
                                .background(.indigo)
                                .clipShape(Capsule())
                        )
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: ViewBuilder

private extension GatherOnboardingView {
    @ViewBuilder
    func featureListView() -> some View {
        VStack(alignment: .leading) {
            featureView(
                image: "house.circle.fill",
                headline: "Environment To Be Scanned",
                subheadline: "Scan your room partially (Example: your desk setup) not farther than 2 meters from your phone."
            )
            
            featureView(
                image: "timer.circle.fill",
                headline: "Scanning Time",
                subheadline: "Scan your surrounding for around 1-3 seconds while moving slowly."
            )
            
            featureView(
                image: "exclamationmark.circle.fill",
                headline: "Be Aware of Your Surroundings",
                subheadline: "Watch out of your surroundings while scanning to avoid accidents."
            )
        }
    }
    
    @ViewBuilder
    func featureView(image: String, headline: String, subheadline: String) -> some View {
        HStack {
            Image(systemName: image)
                .font(.largeTitle)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(headline)
                    .font(.headline)
                    .bold()
                
                Text(subheadline)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .multilineTextAlignment(.leading)
        }
        .padding()
    }
}

// MARK: Public Modifier

extension GatherOnboardingView {
    
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
    GatherOnboardingView()
}

