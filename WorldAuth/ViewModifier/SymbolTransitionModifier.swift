//
//  SymbolTransitionModifier.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/08/27.
//

import SwiftUI

struct SymbolTransitionModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
        } else {
            content.contentTransition(.symbolEffect(.replace))
        }
    }
}
