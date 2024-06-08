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
    @State private var selectedTab: Int = 0
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                provideTab(
                    selectedTab: 0,
                    alt: "Authentication",
                    systemImage: "key.fill"
                )
                
                provideTab(
                    selectedTab: 1,
                    alt: "Locations",
                    systemImage: "mappin.and.ellipse.circle.fill"
                )
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
        selectedTab: Int,
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
