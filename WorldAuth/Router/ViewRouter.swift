//
//  ViewRouter.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/08.
//

import SwiftUI

struct ViewRouter<T: Hashable, Content: View>: View {
    @ObservedObject var router: Router<T>
    @ViewBuilder var buildView: (T) -> Content
    @StateObject var viewModel: AppViewModel = AppViewModel()
    
    var body: some View {
        NavigationStack(path: $router.paths) {
            buildView(router.root)
                .environmentObject(viewModel)
                .navigationDestination(for: T.self) { path in
                    buildView(path)
                        .environmentObject(viewModel)
                }
        }
        .environmentObject(router)
    }
}
