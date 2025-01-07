//
//  UIViewWrapper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/01/07.
//

import SwiftUI

struct UIViewWrapper<V: UIView>: UIViewRepresentable {
    
    let view: UIView
    
    func makeUIView(context: Context) -> some UIView { view }
    func updateUIView(_ uiView: UIViewType, context: Context) { }
}
