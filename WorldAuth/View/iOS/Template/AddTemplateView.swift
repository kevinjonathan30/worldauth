//
//  AddTemplateView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/01.
//

import SwiftUI
import Combine
import AudioToolbox

struct AddTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewState: ViewState = .loaded
    @State private var showAlert = false
    @State private var showInputAlert = false
    @State private var article = AlertArticle(title: "", description: "")
    @State private var roomName: String = ""
    @State private var tempPlyString: String = ""
    
    var body: some View {
        ARContainerView(viewState: $viewState)
            .onFinishRecording(register(plyString:uiImage:))
            .alert(article.title, isPresented: $showAlert, presenting: article) { _ in
                Button("Close", role: .cancel) {
                    showAlert = false
                    dismiss()
                }
            } message: { article in
                Text(article.description)
            }
            .textFieldAlert(isPresented: $showInputAlert, title: "Enter Room Name", message: "Leave blank to save with today's date") { name in
                saveTemplate(named: name) // Pass the user input to saveTemplate
            }
            .navigationTitle("Add New Template")
            .toolbar(.hidden, for: .tabBar)
            .accessibilityElement()
            .accessibilityLabel(Text("Add New Template View", comment: "Accessibility label for Add New Template view"))
            .accessibilityHint(Text("Add New Template using AR", comment: "Accessibility hint for Add New Template view"))
    }
}

// MARK: Handler

private extension AddTemplateView {
    private func register(plyString: String, uiImage: UIImage?) {
        guard !plyString.isEmpty else { return }
        viewState = .loading
        
        if RemoteConfigProvider.shared.prefersOnDevice() {
            guard FileHelper.getFileList().count < 3 else {
                viewState = .loaded
                article = AlertArticle(title: "An Error Occurred", description: "You can only add a maximum of 3 room templates.")
                showAlert = true
                return
            }
            
            showInputAlert = true
            tempPlyString = plyString
        } else {
            NetworkHelper.registerPointCloud(Data(plyString.utf8)) { data, error in
                if let error = error {
                    viewState = .loaded
                    article = AlertArticle(title: "An Error Occurred", description: error.localizedDescription)
                    showAlert = true
                } else {
                    guard let data = data else {
                        viewState = .loaded
                        return
                    }
                    
                    if data.success == true {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            dismiss()
                            viewState = .loaded
                        }
                    } else {
                        viewState = .loaded
                        LoggerHelper.logError(
                            parameters: [
                                .message: data.error ?? "",
                            ]
                        )
                    }
                }
            }
        }
    }
    
    private func saveTemplate(named name: String?) {
        let fallbackName = DateFormatter.localizedString(
            from: Date(),
            dateStyle: .short,
            timeStyle: .medium
        ).replacingOccurrences(of: "/", with: "-")
         .replacingOccurrences(of: ":", with: "-")
        
        let fileName = (name?.isEmpty ?? true)
            ? "\(fallbackName).ply"
            : "\(name ?? "").ply"
        
        // Save the PLY file
        let url = FileHelper.saveFile(data: Data(tempPlyString.utf8), fileName: fileName)
        if url != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
                viewState = .loaded
            }
        } else {
            viewState = .loaded
        }
        tempPlyString = "" // Reset the temp string
    }
}

#Preview {
    AddTemplateView()
}
