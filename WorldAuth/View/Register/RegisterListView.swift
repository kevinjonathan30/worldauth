//
//  RegisterListView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/06.
//

import SwiftUI
import ZIPFoundation

struct RegisterListView: View {
    @State var pointCloudList: [WorldTemplate] = []
    @State var viewState: ViewState = .loading
    
    var body: some View {
        ZStack {
            switch viewState {
            case .empty:
                Text("No Saved Room Template")
                    .accessibilityLabel(Text("No Saved Room Template Text", comment: "Accessibility label for text"))
                    .accessibilityHint(Text("No saved room template", comment: "Accessibility hint for text"))
                    .accessibilityAddTraits([.isStaticText])
            case .fail:
                Text("Failed to Load Room Template")
                    .accessibilityLabel(Text("Failed To Load Room Text", comment: "Accessibility label for text"))
                    .accessibilityHint(Text("Failed to Load Room Template", comment: "Accessibility hint for text"))
                    .accessibilityAddTraits([.isStaticText])
            case .loading:
                ProgressView()
                    .accessibilityLabel(Text("Loading Progress View", comment: "Accessibility label for Progress View"))
                    .accessibilityHint(Text("Loading Data", comment: "Accessibility hint for Progress View"))
            case .loaded:
                ScrollView {
                    LazyVStack {
                        ForEach(pointCloudList) { worldTemplate in
                            cardView(worldTemplate: worldTemplate)
                        }
                    }
                }
                .padding(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
            
            floatingButton()
        }
        .navigationTitle("My Room Template")
        .onAppear {
            getPointCloudList()
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
                    Text(worldTemplate.pcdName)
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
            }
            .accessibilityLabel(Text("Delete Button", comment: "Accessibility label for Button"))
            .accessibilityHint(Text("Delete \(worldTemplate.pcdName)", comment: "Accessibility hint for Button"))
            .accessibilityAddTraits([.isButton])
        }
        ProgressView()
            .accessibilityLabel(Text("Room Template Card View", comment: "Accessibility label for Card View"))
            .accessibilityHint(Text("\(worldTemplate.pcdName). Please hold to delete", comment: "Accessibility hint for Progress View"))
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
            .accessibilityLabel(Text("Add New Floating Button", comment: "Accessibility label for Button"))
            .accessibilityHint(Text("Add New Room Template", comment: "Accessibility hint for Button"))
            .accessibilityAddTraits([.isButton])
        }
        .transaction { transaction in
            transaction.animation = .none
        }
    }
}

// MARK: Handler

private extension RegisterListView {
    private func getPointCloudList() {
        viewState = .loading
        NetworkHelper.getPointCloud { data, error in
            if let error = error {
                print(error.localizedDescription)
                viewState = .fail
            } else {
                guard let data = data else {
                    viewState = .fail
                    return
                }
                pointCloudList = data
                viewState = pointCloudList.isEmpty ? .empty : .loaded
            }
        }
    }
    
    private func delete(worldTemplate: WorldTemplate) {
        NetworkHelper.deletePointCloud(fileName: worldTemplate.pcdName) { data, error in
            if let error = error {
                print(error.localizedDescription)
                viewState = .fail
            } else {
                guard let data = data else { return }
                if data.success ?? false {
                    getPointCloudList()
                }
            }
        }
    }
}

#Preview {
    RegisterListView()
}
