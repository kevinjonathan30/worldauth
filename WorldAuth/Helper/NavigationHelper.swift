//
//  NavigationHelper.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2024/06/08.
//

import UIKit

struct NavigationHelper {
    static private var selectedTab: TabState = .authentication
    static private var authRouter = Router<Path>(root: .root)
    static private var listRouter = Router<Path>(root: .root)
    
    static func setSelectedTab(newSelectedTab: TabState) {
        selectedTab = newSelectedTab
    }
    
    static func getRouter() -> Router<Path> {
        switch selectedTab {
        case .authentication:
            return authRouter
        case .locations:
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

