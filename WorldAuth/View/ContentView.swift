//
//  ContentView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/03.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    var selectedTab: Int = 0
    
    var body: some View {
        ViewRouter(router: NavigationHelper.getRouter()) { path in
            switch path {
            case .root:
                determineView()
            case .registerView:
                LazyView(
                    RegisterView()
                )
            }
        }
    }
}

extension ContentView {
    @ViewBuilder
    func determineView() -> some View {
        switch self.selectedTab {
        case 0:
            LazyView(
                AuthenticationView()
            )
        default:
            LazyView(
                RegisterListView()
            )
        }
    }
}

#Preview {
    ContentView(selectedTab: 0)
}
