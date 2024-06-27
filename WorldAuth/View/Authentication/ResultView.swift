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
            
            Spacer()
            
            Text(success ? "Authentication Success" : "Authentication Failed")
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
    }
}

#Preview {
    ResultView(success: true, similarity: 1.0)
}
