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
            TabView(selection: $selectedTab) {
                provideTab(
                    selectedTab: .authentication,
                    alt: "Authentication",
                    systemImage: "key.fill"
                )
                .accessibilityElement()
                .accessibilityLabel(Text("Authentication Tab Menu", comment: "Accessibility label for authentication tab"))
                .accessibilityHint(Text("Tap to view authentication options", comment: "Accessibility hint for authentication tab"))
                .accessibilityAddTraits(.isButton)
                
                provideTab(
                    selectedTab: .rooms,
                    alt: "My Room",
                    systemImage: "house.fill"
                )
                .accessibilityElement()
                .accessibilityLabel(Text("My Room Tab Menu", comment: "Accessibility label for my room tab"))
                .accessibilityHint(Text("Tap to view your room list", comment: "Accessibility hint for my room tab"))
                .accessibilityAddTraits(.isButton)
            }
            .onChange(of: selectedTab) { newSelectedTab in
                NavigationHelper.pop()
                NavigationHelper.setSelectedTab(
                    newSelectedTab: newSelectedTab
                )
            }
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
