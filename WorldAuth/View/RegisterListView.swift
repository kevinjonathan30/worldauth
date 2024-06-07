//
//  RegisterListView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/06.
//

import SwiftUI

struct RegisterListView: View {
    @State var fileList: [URL] = []
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        VStack {
            switch(fileList.count) {
            case 0:
                Text("No Saved Point Cloud")
            default:
                List {
                    ForEach(fileList, id: \.self) { fileURL in
                        Text(fileURL.lastPathComponent)
                    }
                    .onDelete(perform: delete)
                }
            }
        }
        .onAppear {
            fileList = FileHelper.getFileList(atDirectory: "ply")
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

// MARK: Handler

private extension RegisterListView {
    private func delete(at offsets: IndexSet) {
        var fileUrl: URL?
        for index in offsets {
            fileUrl = fileList[index]
            
            if FileHelper.deleteFile(atDirectory: "ply", fileName: fileUrl?.absoluteString ?? "") {
                fileList = FileHelper.getFileList(atDirectory: "ply")
            }
        }
    }
}

#Preview {
    RegisterListView()
}
