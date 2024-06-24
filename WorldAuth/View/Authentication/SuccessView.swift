//
//  SuccessView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/24.
//

import SwiftUI

struct SuccessView: View {
    let similarity: Double
    
    init(similarity: Double = 0) {
        self.similarity = similarity
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: "lock.open.fill")
                .font(.largeTitle)
            
            Spacer()
            
            Text("Authentication Success")
                .font(.title2)
                .bold()
            
            Text("Similarity: \(similarity * 100)%")
            
            Spacer()
            
            backButton()
            
            Spacer()
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }
}

private extension SuccessView {
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
    }
}

#Preview {
    SuccessView(similarity: 0.8)
}
