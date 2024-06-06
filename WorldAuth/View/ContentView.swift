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
        VStack {
            LazyView(
                AuthenticationView()
                    .environmentObject(viewModel)
            )
        }
        .navigationTitle("WorldAuth")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                NavigationLink(
                    destination: LazyView(
                        RegisterView()
                            .environmentObject(viewModel)
                    )
                ) {
                    Text("Register")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
