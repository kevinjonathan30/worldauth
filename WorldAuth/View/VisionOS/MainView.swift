//
//  MainView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/02/06.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        Text("Please look around to scan your surroundings.")
            .onAppear {
                Task {
                    await openSceneReconstruction()
                }
            }
    }

    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    private func openSceneReconstruction() async {
        await openImmersiveSpace(id: "SceneReconstruction")
    }
}

#Preview(windowStyle: .automatic) {
    MainView()
}

