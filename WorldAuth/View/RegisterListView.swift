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
                }
            }
        }
        .onAppear {
            getFileList()
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
            print("Error while enumerating files: \(error.localizedDescription)")
            return
        }
    }
}

#Preview {
    RegisterListView()
}
