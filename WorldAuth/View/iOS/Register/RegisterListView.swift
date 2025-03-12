//
//  RegisterListView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/06.
//

import SwiftUI

struct RegisterListView: View {
    @State var roomList: [WorldTemplate] = []
    @State var viewState: ViewState = .loading
    @State var searchQuery: String = ""
    @State private var showAlert = false
    @State private var article = AlertArticle(title: "", description: "")
    
    var filteredRoomList: [WorldTemplate] {
        guard !searchQuery.isEmpty else { return roomList }
        return roomList
            .filter { $0.pcdName.replacingOccurrences(of: ".ply", with: "").replacingOccurrences(of: "_", with: " ").contains(searchQuery) }
    }
    
    var body: some View {
        ZStack {
            switch viewState {
            case .empty:
                Text("No Scanned Room Template")
                    .accessibilityElement()
                    .accessibilityLabel(Text("No Scanned Room Template Text", comment: "Accessibility label for text"))
                    .accessibilityHint(Text("There are no scanned room templates.", comment: "Accessibility hint for text"))
                    .accessibilityAddTraits([.isStaticText])
            case .fail:
                Text("Failed to Load Room Template")
                    .accessibilityElement()
                    .accessibilityLabel(Text("Failed To Load Room Text", comment: "Accessibility label for text"))
                    .accessibilityHint(Text("Failed to load room templates. Please try again later.", comment: "Accessibility hint for text"))
                    .accessibilityAddTraits([.isStaticText])
            case .loading:
                ProgressView()
                    .accessibilityElement()
                    .accessibilityLabel(Text("Loading Progress View", comment: "Accessibility label for Progress View"))
                    .accessibilityHint(Text("Loading data. Please wait.", comment: "Accessibility hint for Progress View"))
            case .loaded:
                List {
                    ForEach(filteredRoomList.sorted(by: {$0.pcdName < $1.pcdName})) { worldTemplate in
                        Text(worldTemplate.pcdName.replacingOccurrences(of: ".ply", with: "").replacingOccurrences(of: "_", with: " "))
                            .bold()
                            .opacity(0.8)
                            .swipeActions(edge: .trailing) {
                                Button {
                                    delete(worldTemplate: worldTemplate)
                                } label: {
                                    Image(systemName: "trash.fill")
                                        .resizable()
                                }
                                .tint(.red)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    delete(worldTemplate: worldTemplate)
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                        .accessibilityElement()
                                        .accessibilityLabel(Text("Delete Button", comment: "Accessibility label for delete button"))
                                        .accessibilityHint(Text("Delete \(worldTemplate.pcdName.replacingOccurrences(of: ".pcd", with: ""))", comment: "Accessibility hint for delete button"))
                                        .accessibilityAddTraits([.isButton])
                                }
                            }
                    }
                }
                .searchable(text: $searchQuery)
                .refreshable {
                    getRoomList()
                }
            }
            
            floatingButton()
        }
        .navigationTitle("My Room Template")
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
    }
}

// MARK: Views

private extension RegisterListView {
    @ViewBuilder
    private func cardView(worldTemplate: WorldTemplate) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                HStack {
                    Text(worldTemplate.pcdName.replacingOccurrences(of: ".ply", with: "").replacingOccurrences(of: "_", with: " "))
                        .bold()
                        .opacity(0.8)
                    
                    Spacer()
                }.padding(.bottom, 1)
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
                delete(worldTemplate: worldTemplate)
            } label: {
                Label("Delete", systemImage: "trash.fill")
                    .accessibilityElement()
                    .accessibilityLabel(Text("Delete Button", comment: "Accessibility label for delete button"))
                    .accessibilityHint(Text("Delete \(worldTemplate.pcdName.replacingOccurrences(of: ".pcd", with: ""))", comment: "Accessibility hint for delete button"))
                    .accessibilityAddTraits([.isButton])
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text("Room Template Card View", comment: "Accessibility label for card view"))
        .accessibilityHint(Text("Tap and hold to delete \(worldTemplate.pcdName.replacingOccurrences(of: ".pcd", with: ""))", comment: "Accessibility hint for card view"))
    }
    
    @ViewBuilder
    private func floatingButton() -> some View {
        if viewState == .empty || viewState == .loaded {
            VStack {
                Spacer()
                
                NavigationLink(
                    destination: LazyView(
                        RegisterView()
                            .accessibilityElement()
                            .accessibilityLabel(Text("Register View", comment: "Accessibility label for register view"))
                            .accessibilityHint(Text("View to register point clouds", comment: "Accessibility hint for register view"))
                    )
                ) {
                    Text("Add New")
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.accentColor)
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

// MARK: Handler

private extension RegisterListView {
    private func getRoomList() {
        viewState = .loading
        if RemoteConfigProvider.shared.prefersOnDevice() && RemoteConfigProvider.shared.authenticationMethod() == "DGMR" {
            let fileList = FileHelper.getFileList()
            roomList = fileList.map { WorldTemplate(pcdName: $0.lastPathComponent) }
            viewState = filteredRoomList.isEmpty ? .empty : .loaded
        } else {
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
    }
    
    private func delete(worldTemplate: WorldTemplate) {
        if RemoteConfigProvider.shared.prefersOnDevice() && RemoteConfigProvider.shared.authenticationMethod() == "DGMR" {
            let isDeleted = FileHelper.deleteFile(fileName: worldTemplate.pcdName)
            if isDeleted {
                getRoomList()
            }
        } else {
            NetworkHelper.deletePointCloud(fileName: worldTemplate.pcdName) { data, error in
                if let error = error {
                    article = AlertArticle(title: "An Error Occured", description: error.localizedDescription)
                    showAlert = true
                    viewState = .fail
                } else {
                    guard let data = data else { return }
                    if data.success ?? false {
                        getRoomList()
                    }
                }
            }
        }
    }
}

#Preview {
    RegisterListView()
}
