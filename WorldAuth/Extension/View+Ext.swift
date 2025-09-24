//
//  View+Ext.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/09/24.
//

import SwiftUI

extension View {
    @ViewBuilder
    func ignoreBottomSafeAreaIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            self.ignoresSafeArea(.container, edges: .bottom)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func hideToolbarIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            self
        } else {
            self.toolbar(.hidden, for: .tabBar)
        }
    }
}
