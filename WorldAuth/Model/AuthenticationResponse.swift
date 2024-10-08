//
//  AuthenticationResult.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/24.
//

import Foundation

struct AuthenticationResult: Codable {
    let error: String?
    let success: Bool?
    let fitness: Double?
}
