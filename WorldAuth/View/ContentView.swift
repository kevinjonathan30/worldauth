//
//  ContentView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/03.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel: AppViewModel = AppViewModel()
    
    var body: some View {
        TabView {
            LazyView(
                AuthenticationView()
                    .environmentObject(viewModel)
            )
            .tabItem {
                Label("Authentication", systemImage: "key.fill")
            }
            
            LazyView(
                RegisterListView()
                    .environmentObject(viewModel)
            )
            .tabItem {
                Label("Locations", systemImage: "mappin.and.ellipse.circle.fill")
            }
        }
        .navigationTitle("WorldAuth")
    }
}

#Preview {
    ContentView()
}
