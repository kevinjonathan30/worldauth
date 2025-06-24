//
//  GatherView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/06/05.
//

import SwiftUI
import ZIPFoundation

// TODO: Gather user data by getting the point clouds and photo, then proceed by zipping it, uploading to NSL server.
struct GatherView: View {
    @State var viewState: ViewState = .loaded
    @State private var showOnboarding = true
    @State private var showAlert = false
    @State private var showTextFieldAlert = false
    @State private var tempCaptured: (String, String, UIImage?)? = nil
    @State private var article = AlertArticle(title: "", description: "")
    
    var body: some View {
        NavigationStack {
            VStack {
                ARContainerView(viewState: $viewState)
                    .onFinishRecording(showAlertToInputName(plyString:plyStringColored:uiImage:))
                    .navigationTitle("WorldAuth")
                    .alert(article.title, isPresented: $showAlert, presenting: article) { _ in
                        Button("Close", role: .cancel) {
                            showAlert = false
                        }
                    } message: { article in
                        Text(article.description)
                    }
                    .sheet(isPresented: $showOnboarding) {
                        GatherOnboardingView()
                            .confirmAction {
                                showOnboarding = false
                            }
                    }
                    .textFieldAlert(isPresented: $showTextFieldAlert, title: "Enter Room Name", message: "Enter without using spaces") { name in
                        authenticate(name: name ?? "", plyString: tempCaptured?.0 ?? "", plyStringColored: tempCaptured?.1 ?? "", uiImage: tempCaptured?.2)
                    }
                    .onChange(of: tempCaptured?.0) { _, newValue in
                        showTextFieldAlert = newValue != nil
                    }
            }
        }
    }
}

// MARK: Handler

private extension GatherView {
    private func showAlertToInputName(plyString: String, plyStringColored: String, uiImage: UIImage?) {
        tempCaptured = (plyString, plyStringColored, uiImage)
    }
    
    private func authenticate(name: String, plyString: String, plyStringColored: String, uiImage: UIImage?) {
        self.viewState = .loading
        guard !plyString.isEmpty, !plyStringColored.isEmpty, uiImage != nil else {
            self.viewState = .loaded
            article = AlertArticle(title: "Error", description: "Missing required data.")
            showAlert = true
            return
        }
        
        processPlyAndImage(name: name, plyString: plyString, plyStringColored: plyStringColored, uiImage: uiImage)
    }
    
    private func processPlyAndImage(name: String, plyString: String, plyStringColored: String, uiImage: UIImage?) {
        guard let uiImage = uiImage else { return }
        
        guard let imageData = uiImage.jpegData(compressionQuality: 0.9) else {
            LoggerHelper.logError(parameters: [.message: "Error: Unable to convert UIImage to JPEG data"])
            return
        }
        
        let plyData = Data(plyString.utf8)
        let coloredPlyData = Data(plyStringColored.utf8)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let zipFileURL = documentsURL.appendingPathComponent("\(name)-\(dateString).zip")
        
        
        do {
            let archive = try Archive(url: zipFileURL, accessMode: .create)
            // Add the image entry to the archive
            try archive.addEntry(with: "\(name)-image-\(dateString).jpg", type: .file, uncompressedSize: Int64(imageData.count), bufferSize: 4) { (position, size) -> Data in
                return imageData.subdata(in: Data.Index(position)..<Int(position)+size)
            }
            // Add the ply entry to the archive
            try archive.addEntry(with: "\(name)-pointcloud-\(dateString).ply", type: .file, uncompressedSize: Int64(plyData.count), bufferSize: 4) { (position, size) -> Data in
                return plyData.subdata(in: Data.Index(position)..<Int(position)+size)
            }
            // Add the colored ply entry to the archive
            try archive.addEntry(with: "\(name)-coloredpointcloud-\(dateString).ply", type: .file, uncompressedSize: Int64(coloredPlyData.count), bufferSize: 4) { (position, size) -> Data in
                return coloredPlyData.subdata(in: Data.Index(position)..<Int(position)+size)
            }
            
            processPlyOnline(fileName: "\(name)-\(dateString).zip")
        } catch {
            LoggerHelper.logError(parameters: [.message: "Error processing files: \(error)"])
        }
    }
    
    private func processPlyOnline(fileName: String) {
        guard let fileData = FileHelper.getDataByName(fileName: fileName) else { return }
        
        NetworkHelper.uploadData(fileData, fileName: fileName) { data, error in
            if let error = error {
                article = AlertArticle(title: "An Error Occurred", description: error.localizedDescription)
                showAlert = true
                self.viewState = .loaded
            } else {
                DispatchQueue.main.async {
                    article = AlertArticle(title: "Upload Success", description: "You have successfully uploaded a point cloud.")
                    showAlert = true
                    self.viewState = .loaded
                }
            }
        }
    }
    
    private func shareViaAirDrop(zipFileURL: URL) {
        // Share the zip file via AirDrop
        DispatchQueue.main.async {
            let activityViewController = UIActivityViewController(activityItems: [zipFileURL], applicationActivities: nil)
            activityViewController.excludedActivityTypes = [.postToFacebook, .postToTwitter]
            
            // Completion handler to delete the file after sharing
            activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, error in
                if completed {
                    do {
                        try FileManager.default.removeItem(at: zipFileURL)
                        LoggerHelper.logInfo(
                            parameters: [
                                .message: "Temporary ZIP file deleted successfully.",
                            ]
                        )
                    } catch {
                        LoggerHelper.logError(parameters: [.message: "Error deleting temporary ZIP file: \(error)"])
                    }
                }
                viewState = .loaded
            }
            
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                scene.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
            }
        }
    }
}

#Preview {
    GatherView()
}
