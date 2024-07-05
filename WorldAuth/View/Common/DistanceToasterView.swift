//
//  DistanceToasterView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/07/05.
//

import SwiftUI

struct DistanceToasterView: View {
    @Binding var isIdealDistance: DistanceState
    
    var body: some View {
        VStack {
            Text(getDistanceState())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .opacity(isIdealDistance == .normal ? 0 : 0.75)
                        .zIndex(999)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 8)
                        )
                )
                .padding()
            
            Spacer()
        }
        .padding(.top, 32)
        .animation(.bouncy, value: isIdealDistance)
        .zIndex(999)
    }
}

private extension DistanceToasterView {
    private func getDistanceState() -> String {
        switch isIdealDistance {
        case .normal:
            return ""
        case .close:
            return "Your device is too close to the environment, please step farther."
        case .far:
            return "Your device is too far from the environment, please step closer."
        }
    }
}

#Preview {
    DistanceToasterView(isIdealDistance: .constant(.normal))
}
