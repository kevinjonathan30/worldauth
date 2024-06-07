//
//  RegisterListView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/06.
//

import SwiftUI

struct RegisterListView: View {
    @State var fileList: [URL] = []
    
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
            getFileList()
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                NavigationLink(
                    destination: LazyView(
                        RegisterView()
                    )
                ) {
                    Text("Add New")
                }
            }
        }
    }
    
    func getFileList() {
        let fileManager = FileManager.default
        let documentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            // Get contents of directory
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectoryURL, includingPropertiesForKeys: nil)
            fileList = fileURLs
        } catch {
            // Handle error
            print(error.localizedDescription)
            return
        }
    }
    
    func delete(at offsets: IndexSet) {
        var fileUrl: URL?
        for index in offsets {
            fileUrl = fileList[index] // TODO: Add delete file
        }
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: fileUrl?.absoluteString ?? "") else { return }
        
        do {
            try fileManager.removeItem(atPath: fileUrl?.absoluteString ?? "")
        } catch {
            print(error.localizedDescription)
        }
    }
}

#Preview {
    RegisterListView()
}
