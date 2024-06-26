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
                )
            case .successView(let similarity):
                LazyView(
                    SuccessView(similarity: similarity)
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
            )
        case .locations:
            LazyView(
                RegisterListView()
            )
        }
    }
}

#Preview {
    ContentView(selectedTab: .authentication)
}
