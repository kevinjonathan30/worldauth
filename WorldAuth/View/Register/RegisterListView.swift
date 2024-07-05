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
            case .fail:
                Text("Failed to Load Room Template")
            case .loading:
                ProgressView()
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
        .navigationTitle("Saved")
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
                guard let data = data else { return }
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
