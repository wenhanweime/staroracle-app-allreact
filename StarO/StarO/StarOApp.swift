//
//  StarOApp.swift
//  StarO
//
//  Created by pot on 11/8/25.
//

import SwiftUI

@main
struct StarOApp: App {
  @StateObject private var environment = AppEnvironment()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(environment)
        .environmentObject(environment.authService)
        .environmentObject(environment.starStore)
        .environmentObject(environment.chatStore)
        .environmentObject(environment.galaxyStore)
        .environmentObject(environment.galaxyGridStore)
        .environmentObject(environment.conversationStore)
        .environmentObject(environment.chatBridge)
        .task {
          await environment.authService.restoreSessionIfNeeded()
        }
    }
  }
}
