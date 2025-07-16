//
//  OnboardingPageView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/07/16.
//

import SwiftUI

struct OnboardingPageView {
    let imageName: String
    let headline: String
    let subheadline: String

    var image: some View {
        Image(systemName: imageName)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 150)
            .foregroundColor(.blue)
            .padding()
    }
}
