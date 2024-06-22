//
//  RegisterListView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/06.
//

import SwiftUI
import ZIPFoundation

struct RegisterListView: View {
    @State var fileList: [WorldTemplate] = []
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        ZStack {
            switch(fileList.count) {
            case 0:
                Text("No Saved Point Cloud")
            default:
                ScrollView {
                    LazyVStack {
                        ForEach(fileList) { file in
                            cardView(file: file)
                        }
                    }
                }
                .padding(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
            
            floatingButton()
        }
        .navigationTitle("Locations")
        .toolbar(.hidden)
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            fileList = getPlyAndImageList()
        }
    }
}

// MARK: Views

private extension RegisterListView {
    @ViewBuilder
    private func cardView(file: WorldTemplate) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                HStack {
                    Text(file.plyUrl.lastPathComponent)
                        .bold()
                        .opacity(0.8)
                    
                    Spacer()
                }.padding(.bottom, 1)
                
                loadImageFromURL(fileName: file.imgUrl.lastPathComponent)
                    .resizable()
                    .scaledToFit()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.quaternary)
                .opacity(0.5)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contextMenu {
            Button {
                shareFiles(plyUrl: file.plyUrl)
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                
            }
            
            Button(role: .destructive) {
                delete(plyUrl: file.plyUrl, imgUrl: file.imgUrl)
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        }
    }
    
    @ViewBuilder
    private func floatingButton() -> some View {
        VStack {
            Spacer()
            
            Button {
                NavigationHelper.push(.registerView)
            } label: {
                Text("Add New")
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        Capsule(style: .continuous)
                            .background(.accent)
                            .clipShape(Capsule())
                    )
            }
        }
        .transaction { transaction in
            transaction.animation = .none
        }
    }
    
    func loadImageFromURL(fileName: String) -> Image {
        guard let imageData = FileHelper.getDataByName(atDirectory: "img", fileName: fileName),
              let uiImage = UIImage(data: imageData) else {
            return Image(systemName: "photo")
        }
        
        return Image(uiImage: uiImage)
    }
}

// MARK: Handler

private extension RegisterListView {
    private func getPlyAndImageList() -> [WorldTemplate] {
        let plyFiles = FileHelper.getFileList(atDirectory: "ply")
        let imgFiles = FileHelper.getFileList(atDirectory: "img")
        var templates: [WorldTemplate] = []
        
        for (index, _) in plyFiles.enumerated() {
            guard let plyFile = plyFiles[safe: index], let imgFile = imgFiles[safe: index] else { continue }
            templates.append(WorldTemplate(plyUrl: plyFile, imgUrl: imgFile))
        }
        
        return templates
    }
    
    private func delete(plyUrl: URL, imgUrl: URL) {
        if FileHelper.deleteFile(atDirectory: "ply", fileName: plyUrl.lastPathComponent),
           FileHelper.deleteFile(atDirectory: "img", fileName: imgUrl.lastPathComponent) {
            fileList = getPlyAndImageList()
        }
    }
    
    private func shareFiles(plyUrl: URL) {
        DispatchQueue.main.async {
            let activityViewController = UIActivityViewController(activityItems: [plyUrl], applicationActivities: nil)
            activityViewController.completionWithItemsHandler =  { _, _, _, _ in
                
            }
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                scene.windows.first?.rootViewController?.present(
                    activityViewController,
                    animated: true,
                    completion: nil
                )
            }
        }
    }
}

#Preview {
    RegisterListView()
}
