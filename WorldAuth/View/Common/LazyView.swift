//
//  LazyView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/05.
//

import SwiftUI

// Use this if a lazy load view is needed
struct LazyView<Content: View>: View {
    let content: () -> Content

    init(_ content: @autoclosure @escaping () -> Content) {
        self.content = content
    }

    var body: Content {
        content()
    }
}

