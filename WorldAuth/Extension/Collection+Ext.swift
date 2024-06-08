//
//  Collection+Ext.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/05.
//

import Foundation

extension Collection {
    // Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

