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
    @State private var showAlert = false
    @State private var article = AlertArticle(title: "", description: "")
    
    var body: some View {
        NavigationStack {
            VStack {
                ARContainerView(viewState: $viewState)
                    .onFinishRecording(authenticate(plyString:uiImage:))
                    .navigationTitle("WorldAuth")
                    .alert(article.title, isPresented: $showAlert, presenting: article) { _ in
                        Button("Close", role: .cancel) {
                            showAlert = false
                        }
                    } message: { article in
                        Text(article.description)
                    }
            }
        }
    }
}

// MARK: Handler

private extension GatherView {
    private func authenticate(plyString: String, uiImage: UIImage?) {
        self.viewState = .loading
        guard !plyString.isEmpty, uiImage != nil else { return }
        
        processPlyAndImage(plyString: plyString, uiImage: uiImage)
    }
    
    private func processPlyAndImage(plyString: String, uiImage: UIImage?) {
        guard let uiImage = uiImage else { return }
        
        guard let imageData = uiImage.jpegData(compressionQuality: 0.9) else {
            print("Error: Unable to convert UIImage to JPEG data")
            return
        }
        
        let plyData = Data(plyString.utf8)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let zipFileURL = documentsURL.appendingPathComponent("archive-\(dateString).zip")
        
        
        do {
            let archive = try Archive(url: zipFileURL, accessMode: .create)
            // Add the image entry to the archive
            try archive.addEntry(with: "image-\(dateString).jpg", type: .file, uncompressedSize: Int64(imageData.count), bufferSize: 4) { (position, size) -> Data in
                return imageData.subdata(in: Data.Index(position)..<Int(position)+size)
            }
            // Add the ply entry to the archive
            try archive.addEntry(with: "pointcloud-\(dateString).ply", type: .file, uncompressedSize: Int64(plyData.count), bufferSize: 4) { (position, size) -> Data in
                return plyData.subdata(in: Data.Index(position)..<Int(position)+size)
            }
            
            processPlyOnline(fileName: "archive-\(dateString).zip")
        } catch {
            print("Error processing files: \(error)")
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
                        print("Temporary ZIP file deleted successfully.")
                    } catch {
                        print("Error deleting temporary ZIP file: \(error)")
                    }
                }
                viewState = .loaded
            }
            
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                scene.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
            }
        }
    }
    
    #Preview {
        GatherView()
    }
}
