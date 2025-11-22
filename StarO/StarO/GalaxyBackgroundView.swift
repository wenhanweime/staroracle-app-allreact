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
  @State private var debounceTask: Task<Void, Never>?
  var isTapEnabled: Bool = true

  var body: some View {
    GeometryReader { proxy in
      GalaxyMetalContainer(
        viewModel: viewModel,
        size: proxy.size,
        onRegionSelected: nil,
        onTap: { point, size, region, timestamp in
          // Cancel previous task to prevent card generation from previous rapid taps
          debounceTask?.cancel()
          
          debounceTask = Task {
            // Wait for 600ms to allow rapid tapping (exploration)
            // Only the last tap will trigger the card generation AND the highlight
            try? await Task.sleep(nanoseconds: 600_000_000)
            
            if !Task.isCancelled {
              await MainActor.run {
                // Trigger PERMANENT highlight for the valid tap
                viewModel.triggerHighlight(at: point, in: size, tapTimestamp: timestamp, isPermanent: true)
                
                let xPct = Double(point.x / size.width) * 100.0
                let yPct = Double(point.y / size.height) * 100.0
                starStore.setIsAsking(false, position: StarPosition(x: xPct, y: yPct))
                
                _ = starStore.drawInspirationCard(region: region)
                lastTapRegion = region
                lastTapDate = Date()
              }
            }
          }
        },
        isTapEnabled: isTapEnabled
      )
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
