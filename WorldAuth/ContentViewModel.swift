//
//  ContentViewModel.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/01.
//

import UIKit

class ContentViewModel: ObservableObject {
    @Published var capturedPlyFileURLs: [URL] = []
    @Published var capturedImageURLs: [URL] = []
}
