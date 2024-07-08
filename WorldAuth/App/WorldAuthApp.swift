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
                .accessibilityLabel(Text("Authentication Tab Menu", comment: "Accessibility label for tab menu"))
                .accessibilityHint(Text("Authentication menu", comment: "Accessibility hint for tab menu"))
                
                provideTab(
                    selectedTab: .locations,
                    alt: "My Room",
                    systemImage: "house.fill"
                )
                .accessibilityLabel(Text("My Room Tab Menu", comment: "Accessibility label for tab menu"))
                .accessibilityHint(Text("My room menu", comment: "Accessibility hint for tab menu"))
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
            }
    }
}
