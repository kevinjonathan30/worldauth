//
//  RegisterListView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/06.
//

import SwiftUI

struct RegisterListView: View {
    @State var fileList: [Template] = []
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        VStack {
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
        }
        .onAppear {
            fileList = getPlyAndImageList()
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                NavigationLink(
                    destination: LazyView(
                        RegisterView()
                            .environmentObject(viewModel)
                    )
                ) {
                    Text("Add New")
                }
            }
        }
    }
}

// MARK: Views

private extension RegisterListView {
    @ViewBuilder
    private func cardView(file: Template) -> some View {
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
            Button(role: .destructive) {
                delete(plyUrl: file.plyUrl, imgUrl: file.imgUrl)
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        }
    }
    
    func loadImageFromURL(fileName: String) -> Image {
        guard let imageData = FileHelper.getImageDataByName(atDirectory: "img", fileName: fileName),
              let uiImage = UIImage(data: imageData) else {
            return Image(systemName: "photo")
        }

        return Image(uiImage: uiImage)
    }
}

// MARK: Handler

private extension RegisterListView {
    private func getPlyAndImageList() -> [Template] {
        let plyFiles = FileHelper.getFileList(atDirectory: "ply")
        let imgFiles = FileHelper.getFileList(atDirectory: "img")
        var templates: [Template] = []
        
        for (index, _) in plyFiles.enumerated() {
            guard let plyFile = plyFiles[safe: index], let imgFile = imgFiles[safe: index] else { continue }
            templates.append(Template(plyUrl: plyFile, imgUrl: imgFile))
        }
        
        return templates
    }
    
    private func delete(plyUrl: URL, imgUrl: URL) {
        if FileHelper.deleteFile(atDirectory: "ply", fileName: plyUrl.lastPathComponent),
           FileHelper.deleteFile(atDirectory: "img", fileName: imgUrl.lastPathComponent) {
            fileList = getPlyAndImageList()
        }
    }
}

#Preview {
    RegisterListView()
}
