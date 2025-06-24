//
//  RoomTemplateListView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/06.
//

import SwiftUI

struct RoomTemplateListView: View {
    @State var roomList: [SavedPointCloudFile] = []
    @State var viewState: ViewState = .loading
    @State var searchQuery: String = ""
    @State private var showAlert = false
    @State private var article = AlertArticle(title: "", description: "")
    @State private var canNavigate: Bool = false
    @State private var renameTemplate: SavedPointCloudFile? = nil
    
    var filteredRoomList: [SavedPointCloudFile] {
        guard !searchQuery.isEmpty else { return roomList }
        return roomList
            .filter { $0.name.replacingOccurrences(of: ".ply", with: "").contains(searchQuery) }
    }
    
    var body: some View {
        ZStack {
            contentView()
//            floatingButton()
        }
        .navigationTitle("My Room Templates")
        .onAppear {
            getRoomList()
        }
        .alert(article.title, isPresented: $showAlert, presenting: article) { _ in
            Button("Close", role: .cancel) {
                showAlert = false
            }
        } message: { article in
            Text(article.description)
        }
        .textFieldAlert(
            isPresented: Binding<Bool>(
                get: { renameTemplate != nil },
                set: { if !$0 { renameTemplate = nil } }
            ),
            title: "Rename Template",
            message: "Enter the new name for this template",
            required: true,
            initialValue: renameTemplate?.name.replacingOccurrences(of: ".ply", with: ""),
            action: { renameText in
                guard let template = renameTemplate else { return }
                rename(savedPointCloudFile: template, to: renameText ?? "")
                renameTemplate = nil
            }
        )
    }
}

// MARK: Views

private extension RoomTemplateListView {
    @ViewBuilder
    private func contentView() -> some View {
        switch viewState {
        case .empty:
            emptyView()
        case .fail:
            failView()
        case .loading:
            loadingView()
        case .loaded:
            loadedView()
        }
    }
    
    @ViewBuilder
    private func emptyView() -> some View {
        Text("No Saved Room Template")
            .accessibilityElement()
            .accessibilityLabel(Text("No Scanned Room Template Text", comment: "Accessibility label for text"))
            .accessibilityHint(Text("There are no scanned room templates.", comment: "Accessibility hint for text"))
            .accessibilityAddTraits([.isStaticText])
    }
    
    @ViewBuilder
    private func failView() -> some View {
        Text("Failed to Load Room Template")
            .accessibilityElement()
            .accessibilityLabel(Text("Failed To Load Room Text", comment: "Accessibility label for text"))
            .accessibilityHint(Text("Failed to load room templates. Please try again later.", comment: "Accessibility hint for text"))
            .accessibilityAddTraits([.isStaticText])
    }
    
    @ViewBuilder
    private func loadingView() -> some View {
        ProgressView()
            .accessibilityElement()
            .accessibilityLabel(Text("Loading Progress View", comment: "Accessibility label for Progress View"))
            .accessibilityHint(Text("Loading data. Please wait.", comment: "Accessibility hint for Progress View"))
    }
    
    @ViewBuilder
    private func loadedView() -> some View {
        List {
            ForEach(filteredRoomList.sorted(by: { $0.name > $1.name })) { savedPointCloudFile in
                roomTemplateRow(for: savedPointCloudFile)
            }
        }
        .searchable(text: $searchQuery)
        .refreshable {
            getRoomList()
        }
    }
    
    @ViewBuilder
    private func roomTemplateRow(for savedPointCloudFile: SavedPointCloudFile) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(savedPointCloudFile.name.replacingOccurrences(of: ".ply", with: "").replacingOccurrences(of: "_", with: " "))
                    .font(.headline)
                    .bold()
                    .foregroundColor(.primary)
                
//                Text(formatDate(savedPointCloudFile.dateCreated ?? Date()))
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                
//                if let pointCount = savedPointCloudFile.pointCount, pointCount > 0 {
//                    Text("\(pointCount) pts (\(savedPointCloudFile.fileSize ?? "0 bytes"))")
//                        .font(.caption)
//                }
            }
            .padding(.vertical, 4)
            
            Spacer()
        }
        .swipeActions(edge: .trailing) {
            Button {
                delete(savedPointCloudFile: savedPointCloudFile)
            } label: {
                Image(systemName: "trash.fill")
            }
            .tint(.red)
            
//            Button {
//                renameTemplate = savedPointCloudFile
//            } label: {
//                Image(systemName: "pencil")
//            }
//            .tint(.blue)
        }
    }
    
    @ViewBuilder
    private func floatingButton() -> some View {
        if viewState == .empty || viewState == .loaded {
            VStack {
                Spacer()
                
                NavigationLink(
                    destination: LazyView(
                        AddTemplateView()
                            .accessibilityElement()
                            .accessibilityLabel(Text("Register View", comment: "Accessibility label for register view"))
                            .accessibilityHint(Text("View to register point clouds", comment: "Accessibility hint for register view"))
                    ),
                    isActive: $canNavigate
                ) {
                    Button(action: {
                        if filteredRoomList.count < 3 {
                            canNavigate = true
                        } else {
                            article = AlertArticle(title: "Adding a new room template not allowed", description: "You can only add a maximum of 3 room templates.")
                            showAlert = true
                        }
                    }) {
                        Text("Add New Template")
                            .bold()
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                Capsule(style: .continuous)
                                    .fill(filteredRoomList.count < 3 ? Color.accentColor : Color.gray)
                            )
                            .accessibilityElement()
                            .accessibilityLabel(Text("Add New Floating Button", comment: "Accessibility label for add new button"))
                            .accessibilityHint(Text("Add a new room template", comment: "Accessibility hint for add new button"))
                            .accessibilityAddTraits([.isButton])
                    }
                }
                .transaction { transaction in
                    transaction.animation = .none
                }
            }
        }
    }
}

// MARK: Handlers

private extension RoomTemplateListView {
    private func getRoomList() {
        viewState = .loading
//        if RemoteConfigProvider.shared.prefersOnDevice() {
//            let fileList = FileHelper.getFileList()
//            
//            var tempRoomList: [SavedPointCloudFile] = []
//            
//            for file in fileList {
//                let name = file.lastPathComponent
//                let pointCount = PointCloudHelper.extractPointCountFromFile(url: file)
//                let attributes = try? FileManager.default.attributesOfItem(atPath: file.path)
//                let creationDate = attributes?[.creationDate] as? Date ?? Date()
//                let fileSize = FileHelper.getFileSize(url: file)
//                
//                tempRoomList.append(
//                    SavedPointCloudFile(
//                        name: name,
//                        url: file,
//                        pointCount: pointCount,
//                        dateCreated: creationDate,
//                        fileSize: fileSize
//                    )
//                )
//            }
//            
//            roomList = tempRoomList
//            viewState = filteredRoomList.isEmpty ? .empty : .loaded
//        }
        NetworkHelper.getPointCloud { data, error in
            if let error = error {
                article = AlertArticle(title: "An Error Occured", description: error.localizedDescription)
                showAlert = true
                viewState = .fail
            } else {
                guard let data = data else {
                    viewState = .fail
                    return
                }
                roomList = data
                viewState = filteredRoomList.isEmpty ? .empty : .loaded
            }
        }
    }
    
    private func delete(savedPointCloudFile: SavedPointCloudFile) {
//        if FileHelper.deleteFile(fileName: savedPointCloudFile.name) {
//            getRoomList()
//        }
        NetworkHelper.deletePointCloud(fileName: savedPointCloudFile.name) { data, error in
            if let error = error {
                article = AlertArticle(title: "An Error Occured", description: error.localizedDescription)
                showAlert = true
                viewState = .fail
            } else {
                guard let data = data else { return }
                if data.success ?? false {
                    roomList.removeAll { $0.name == savedPointCloudFile.name }
                    if roomList.isEmpty {
                        viewState = .empty
                    } else {
                        viewState = .loaded
                    }
                    let _ = FileHelper.deleteFile(fileName: savedPointCloudFile.name)
                }
            }
        }
    }
    
    private func rename(savedPointCloudFile: SavedPointCloudFile, to newName: String) {
        guard !newName.isEmpty else { return }
        let newFileName = "\(newName).ply"
        
        if FileHelper.renameFile(oldName: savedPointCloudFile.name, newName: newFileName) {
            getRoomList()
        } else {
            article = AlertArticle(title: "Rename Failed", description: "Unable to rename the file. Please try again.")
            showAlert = true
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    RoomTemplateListView()
}
