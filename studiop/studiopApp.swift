//
//  studiopApp.swift
//  studiop
//
//  Created by ngocson on 7/14/26.
//

import SwiftUI

@main
struct studiopApp: App {
    @State var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
    }
}

struct RootView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        if appState.isAuthenticated {
            HomeView(appState: appState)
        } else {
            LoginView(appState: appState)
        }
    }
}
