import SwiftUI
import StarOracleFeatures

@main
struct StarOracleNativeApp: App {
  @StateObject private var environment = AppEnvironment()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(environment)
        .environmentObject(environment.starStore)
        .environmentObject(environment.chatStore)
        .environmentObject(environment.galaxyStore)
        .environmentObject(environment.galaxyGridStore)
    }
  }
}
