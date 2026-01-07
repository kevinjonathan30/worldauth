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
    @State private var article = AlertArticle(title: "", description: "")
    @State private var roomName: String = ""
    
    var body: some View {
        ARContainerView(viewState: $viewState)
            .onFinishRecording(register(plyString:plyStringColored:uiImage:))
            .alert(article.title, isPresented: $showAlert, presenting: article) { _ in
                Button("Close", role: .cancel) {
                    showAlert = false
                    dismiss()
                }
            } message: { article in
                Text(article.description)
            }
            .navigationTitle("Add New Template")
            .hideToolbarIfAvailable()
            .ignoreBottomSafeAreaIfAvailable()
            .accessibilityElement()
            .accessibilityLabel(Text("Add New Template View", comment: "Accessibility label for Add New Template view"))
            .accessibilityHint(Text("Add New Template using AR", comment: "Accessibility hint for Add New Template view"))
    }
}

// MARK: Handler

private extension AddTemplateView {
    private func register(plyString: String, plyStringColored: String, uiImage: UIImage?) {
        guard !plyString.isEmpty else { return }
        viewState = .loading
        
        if RemoteConfigHelper.shared.prefersOnDevice() {
            guard FileHelper.getFileList().count < 3 else {
                viewState = .loaded
                article = AlertArticle(title: "An Error Occurred", description: "You can only add a maximum of 3 room templates.")
                showAlert = true
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                saveTemplate(plyString: plyString)
            }
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
    
    private func saveTemplate(named name: String? = nil, plyString: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let fallbackName = "iOS_PointCloud_\(timestamp)"
        
        let fileName = (name?.isEmpty ?? true)
            ? "\(fallbackName).ply"
            : "\(name ?? "").ply"
        
        // Save the PLY file
        guard let normalizedPlyString = PythonHelper.downsampleAndNormalizePointCloudString(pointCloudString: plyString) else {
            viewState = .loaded
            article = AlertArticle(title: "Error saving point cloud", description: "Point cloud cannot be saved due to conversion error.")
            showAlert = true
            return
        }
        let url = FileHelper.saveFile(data: Data(normalizedPlyString.utf8), fileName: fileName)
        if url != nil {
            viewState = .loaded
            article = AlertArticle(title: "Point cloud saved", description: "Point cloud saved successfully as \(fileName)")
            showAlert = true
        } else {
            viewState = .loaded
            article = AlertArticle(title: "Error saving point cloud", description: "Point cloud cannot be saved due to I/O error.")
            showAlert = true
        }
    }
}

#Preview {
    AddTemplateView()
}
