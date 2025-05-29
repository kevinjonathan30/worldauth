//
//  Array+Ext.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/05/29.
//


// Add this at the bottom of your file, outside any class/struct
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
