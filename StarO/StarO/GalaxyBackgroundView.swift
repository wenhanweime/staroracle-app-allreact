import SwiftUI
import StarOracleCore
import StarOracleFeatures

#if os(iOS)
import UIKit
#endif

struct GalaxyBackgroundView: View {
  @EnvironmentObject private var galaxyStore: GalaxyStore
  @EnvironmentObject private var starStore: StarStore
  @StateObject private var viewModel = GalaxyViewModel()
  
  @State private var lastTapRegion: GalaxyRegion?
  @State private var lastTapDate: Date = .distantPast

  var body: some View {
    GeometryReader { proxy in
      GalaxyMetalContainer(viewModel: viewModel, size: proxy.size) { region in
        // Handle tap/region selection
        _ = starStore.drawInspirationCard(region: region)
        lastTapRegion = region
        lastTapDate = Date()
        
        // Optional: Update galaxyStore state if needed for other components
        // galaxyStore.tap(...) 
      }
      .ignoresSafeArea()
      .overlay(alignment: .topLeading) {
        if let region = lastTapRegion, Date().timeIntervalSince(lastTapDate) < 2 {
          Label("灵感来自 \(regionLabel(region)) 区域", systemImage: "sparkles")
            .font(.caption)
            .padding(8)
            .background(Color.black.opacity(0.4), in: Capsule())
            .padding()
        }
      }
    }
  }

  private func regionLabel(_ region: GalaxyRegion) -> String {
    switch region {
    case .emotion: return "情绪"
    case .relation: return "关系"
    case .growth: return "成长"
    }
  }
}
