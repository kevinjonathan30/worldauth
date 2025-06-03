//
//  TextFieldAlertModifier.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/06/03.
//

import SwiftUI

struct TextFieldAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String?
    let required: Bool
    let initialValue: String?
    let action: (String?) -> Void
    
    @State private var inputText: String = ""
    
    func body(content: Content) -> some View {
        content.alert(title, isPresented: $isPresented) {
            TextField("Room Name", text: $inputText) // Correctly bind the inputText state
            Button("Save") {
                action(inputText.isEmpty ? nil : inputText) // Pass the input text
            }
            .disabled(required && inputText.isEmpty)
            Button("Cancel", role: .cancel) { }
        } message: {
            if let message = message {
                Text(message)
            }
        }
        .onChange(of: isPresented) { _, isPresented in
            if isPresented {
                inputText = initialValue ?? "" // Reset the text field when the alert appears
            }
        }
    }
}

extension View {
    func textFieldAlert(isPresented: Binding<Bool>, title: String, message: String?, required: Bool = false, initialValue: String? = nil, action: @escaping (String?) -> Void) -> some View {
        modifier(TextFieldAlertModifier(isPresented: isPresented, title: title, message: message, required: required, initialValue: initialValue, action: action))
    }
}
