//
//  WorldTemplate.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/07.
//

import Foundation

struct WorldTemplate: Identifiable, Hashable {
    var id: UUID = UUID()
    var plyUrl: URL
    var imgUrl: URL
}
