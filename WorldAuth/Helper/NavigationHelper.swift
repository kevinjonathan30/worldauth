//
//  NavigationHelper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/08.
//

import UIKit

struct NavigationHelper {
    static private var selectedTab: Int = 0
    static private var authRouter = Router<Path>(root: .root)
    static private var listRouter = Router<Path>(root: .root)
    
    static func setSelectedTab(newSelectedTab: Int) {
        selectedTab = newSelectedTab
    }
    
    static func getRouter() -> Router<Path> {
        switch selectedTab {
        case 0:
            return authRouter
        default:
            return listRouter
        }
    }
    
    static func push(_ path: Path) {
        getRouter().push(path)
    }
    
    static func pop() {
        getRouter().pop()
    }
    
    static func popToRoot() {
        getRouter().popToRoot()
    }
}

