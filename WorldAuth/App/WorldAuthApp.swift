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
        WindowGroup {
            CollectView()
        }
    }
}

extension WorldAuthApp {
    private func provideTab(
        selectedTab: TabState,
        alt: String,
        systemImage: String
    ) -> some View {
        ContentView(selectedTab: selectedTab)
            .tag(selectedTab)
            .tabItem {
                Label(alt, systemImage: systemImage)
                    .accessibilityElement()
                    .accessibilityLabel(Text("\(alt) Tab", comment: "Accessibility label for tab item"))
                    .accessibilityHint(Text("Tap to switch to the \(alt) tab", comment: "Accessibility hint for tab item"))
            }
    }
}
