//
//  AuthenticationResult.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/24.
//

import Foundation

// Unified model to match NetworkHelper's response
struct AuthenticationResult: Codable {
    let success: Bool
    let fitness: Double?
    let error: String?
    let detail: String?
}
