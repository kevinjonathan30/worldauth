//
//  ContentView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/03.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
//            NavigationStack {
//                LazyView(
//                    AuthenticationView()
//                        .accessibilityElement()
//                        .accessibilityLabel(Text("Authentication View", comment: "Accessibility label for authentication view"))
//                        .accessibilityHint(Text("View to authenticate users", comment: "Accessibility hint for authentication view"))
//                )
//                .accessibilityElement()
//                .accessibilityLabel(Text("Authentication Tab Menu", comment: "Accessibility label for authentication tab"))
//                .accessibilityHint(Text("Tap to view authentication options", comment: "Accessibility hint for authentication tab"))
//                .accessibilityAddTraits(.isButton)
//            }
//            .tag("Authenticate")
//            .tabItem {
//                Label("Authenticate", systemImage: "key.fill")
//                    .accessibilityElement()
//                    .accessibilityLabel(Text("Authenticate Tab", comment: "Accessibility label for tab item"))
//                    .accessibilityHint(Text("Tap to switch to the Authenticate tab", comment: "Accessibility hint for tab item"))
//            }
            
            NavigationStack {
                LazyView(
                    GatherView()
                )
            }
            .tag("Gather")
            .tabItem {
                Label("Gather", systemImage: "plus.app.fill")
            }
            
            NavigationStack {
                LazyView(
                    RoomTemplateListView()
                        .accessibilityElement()
                        .accessibilityLabel(Text("Register List View", comment: "Accessibility label for register list view"))
                        .accessibilityHint(Text("View showing the list of registered users", comment: "Accessibility hint for register list view"))
                )
                .accessibilityElement()
                .accessibilityLabel(Text("My Room Tab Menu", comment: "Accessibility label for my room tab"))
                .accessibilityHint(Text("Tap to view your room list", comment: "Accessibility hint for my room tab"))
                .accessibilityAddTraits(.isButton)
            }
            .tag("Templates")
            .tabItem {
                Label("Templates", systemImage: "house.fill")
                    .accessibilityElement()
                    .accessibilityLabel(Text("Templates Tab", comment: "Accessibility label for tab item"))
                    .accessibilityHint(Text("Tap to switch to the Templates tab", comment: "Accessibility hint for tab item"))
            }
        }
    }
}

#Preview {
    ContentView()
}
