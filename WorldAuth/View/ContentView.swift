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
            NavigationStack {
                LazyView(
                    AuthenticationView()
                        .accessibilityElement()
                        .accessibilityLabel(Text("Authentication View", comment: "Accessibility label for authentication view"))
                        .accessibilityHint(Text("View to authenticate users", comment: "Accessibility hint for authentication view"))
                )
                .accessibilityElement()
                .accessibilityLabel(Text("Authentication Tab Menu", comment: "Accessibility label for authentication tab"))
                .accessibilityHint(Text("Tap to view authentication options", comment: "Accessibility hint for authentication tab"))
                .accessibilityAddTraits(.isButton)
            }
            .tag("Authentication")
            .tabItem {
                Label("Authentication", systemImage: "key.fill")
                    .accessibilityElement()
                    .accessibilityLabel(Text("Authentication Tab", comment: "Accessibility label for tab item"))
                    .accessibilityHint(Text("Tap to switch to the Authentication tab", comment: "Accessibility hint for tab item"))
            }
            
            NavigationStack {
                LazyView(
                    RegisterListView()
                        .accessibilityElement()
                        .accessibilityLabel(Text("Register List View", comment: "Accessibility label for register list view"))
                        .accessibilityHint(Text("View showing the list of registered users", comment: "Accessibility hint for register list view"))
                )
                .accessibilityElement()
                .accessibilityLabel(Text("My Room Tab Menu", comment: "Accessibility label for my room tab"))
                .accessibilityHint(Text("Tap to view your room list", comment: "Accessibility hint for my room tab"))
                .accessibilityAddTraits(.isButton)
            }
            .tag("My Room Template")
            .tabItem {
                Label("My Room Template", systemImage: "house.fill")
                    .accessibilityElement()
                    .accessibilityLabel(Text("My Room Template Tab", comment: "Accessibility label for tab item"))
                    .accessibilityHint(Text("Tap to switch to the My Room Template tab", comment: "Accessibility hint for tab item"))
            }
        }
    }
}

#Preview {
    ContentView()
}
