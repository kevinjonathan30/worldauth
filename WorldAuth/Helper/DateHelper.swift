//
//  DateHelper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/03.
//

import Foundation

struct DateHelper {
    static func getStringFromDate(date: Date = Date()) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = getDefaultDateFormat()
        return dateFormatter.string(from: date)
    }
    
    static func getDefaultDateFormat() -> String {
        return "yyyy-MM-dd-HH-mm-ss"
    }
}
