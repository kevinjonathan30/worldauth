//
//  MainView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/02/06.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        Text("Scene Reconstruction")
            .onAppear {
                #if os(visionOS)
                Task {
                    await openSceneReconstruction()
                }
                #endif
            }
    }

    #if os(visionOS)
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    private func openSceneReconstruction() async {
        await openImmersiveSpace(id: "SceneReconstruction")
    }
    #endif
}

#if os(visionOS)
#Preview(windowStyle: .automatic) {
    MainView()
}
#endif

