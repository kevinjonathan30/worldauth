//
//  ContentView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/03.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
//            NavigationLink(destination: RegisterView()) {
//                Text("Register")
//            }
//            .padding()
            
            NavigationLink(destination: AuthenticationView()) {
                Text("Authenticate")
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
