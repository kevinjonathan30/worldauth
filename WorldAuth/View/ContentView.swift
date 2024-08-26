//
//  ContentView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/03.
//

import SwiftUI

struct ContentView: View {
    var selectedTab: TabState = .authentication
    
    var body: some View {
        ViewRouter(router: NavigationHelper.getRouter()) { path in
            switch path {
            case .root:
                determineView()
            case .registerView:
                LazyView(
                    RegisterView()
                        .accessibilityElement()
                        .accessibilityLabel(Text("Register View", comment: "Accessibility label for register view"))
                        .accessibilityHint(Text("View to register new users", comment: "Accessibility hint for register view"))
                )
            case .collectView:
                LazyView(
                    CollectView()
                        .accessibilityElement()
                        .accessibilityLabel(Text("Collect View", comment: "Accessibility label for collect view"))
                        .accessibilityHint(Text("View to collect point clouds", comment: "Accessibility hint for collect view"))
                )
            case .successView(let success, let similarity):
                LazyView(
                    ResultView(success: success, similarity: similarity)
                        .accessibilityElement()
                        .accessibilityLabel(Text("Result View", comment: "Accessibility label for result view"))
                        .accessibilityHint(Text("View showing registration results", comment: "Accessibility hint for result view"))
                )
            }
        }
    }
}

extension ContentView {
    @ViewBuilder
    func determineView() -> some View {
        switch self.selectedTab {
        case .authentication:
            LazyView(
                AuthenticationView()
                    .accessibilityElement()
                    .accessibilityLabel(Text("Authentication View", comment: "Accessibility label for authentication view"))
                    .accessibilityHint(Text("View to authenticate users", comment: "Accessibility hint for authentication view"))
            )
        case .rooms:
            LazyView(
                RegisterListView()
                    .accessibilityElement()
                    .accessibilityLabel(Text("Register List View", comment: "Accessibility label for register list view"))
                    .accessibilityHint(Text("View showing the list of registered users", comment: "Accessibility hint for register list view"))
            )
        }
    }
}

#Preview {
    ContentView(selectedTab: .authentication)
}
