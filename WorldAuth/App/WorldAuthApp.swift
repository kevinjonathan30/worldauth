//
//  WorldAuthApp.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/01.
//

import SwiftUI

@main
struct WorldAuthApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var selectedTab: TabState = .authentication
    
    var body: some Scene {
        #if os(iOS)
        WindowGroup {
            ContentView()
        }
        #endif
        
        #if os(visionOS)
        WindowGroup {
            MainView()
        }
        
        ImmersiveSpace(id: "SceneReconstruction") {
            SceneReconstructionView()
        }
        #endif
    }
}
