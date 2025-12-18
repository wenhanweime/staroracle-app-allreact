import SwiftUI
import StarOracleCore
import StarOracleFeatures

#if os(iOS)
import UIKit
#endif

struct GalaxyBackgroundView: View {
  @EnvironmentObject private var galaxyStore: GalaxyStore
  @EnvironmentObject private var starStore: StarStore
  @EnvironmentObject private var conversationStore: ConversationStore
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
          // 纯点击 Galaxy：每次点击都产生“临时高亮（TapHighlight）”，并上报后端做跨设备 1 天同步。
          let ttlExpiresAt = Date().addingTimeInterval(24 * 60 * 60)
          viewModel.triggerHighlight(
            at: point,
            in: size,
            tapTimestamp: timestamp,
            expiresAt: ttlExpiresAt,
            shouldPersist: true
          )

          // Cancel previous task to prevent card generation from previous rapid taps
          debounceTask?.cancel()
          
          // Lock UI during generation
          galaxyStore.setIsGeneratingCard(true)
          
          debounceTask = Task {
            // Wait for 600ms to allow rapid tapping (exploration)
            // Only the last tap will trigger the card generation AND the highlight
            try? await Task.sleep(nanoseconds: 600_000_000)
            
            guard !Task.isCancelled else { return }

            let xPct = Double(point.x / size.width) * 100.0
            let yPct = Double(point.y / size.height) * 100.0
            await MainActor.run {
              starStore.setIsAsking(false, position: StarPosition(x: xPct, y: yPct))
            }

            let remoteCard: InspirationCard?
            if SupabaseRuntime.loadConfig() != nil {
              remoteCard = await StarPluckService.pluckInspiration()
            } else {
              remoteCard = nil
            }

            guard !Task.isCancelled else { return }

            await MainActor.run {
              if let remoteCard {
                starStore.presentInspirationCard(remoteCard)
              } else {
                _ = starStore.drawInspirationCard(region: region)
              }
              lastTapRegion = region
              lastTapDate = Date()

              // Unlock UI
              galaxyStore.setIsGeneratingCard(false)
            }
          }
        },
        isTapEnabled: isTapEnabled
      )
      .ignoresSafeArea()
      .task(id: proxy.size) {
        await MainActor.run {
          updatePermanentStarHighlights(for: proxy.size)
        }
      }
      .onChange(of: starStore.constellation.stars) { _, _ in
        updatePermanentStarHighlights(for: proxy.size)
      }
      .task {
        // T-102: Seed must be fetched from server as the single source of truth.
        if let seed = await GalaxySeedService.fetchSeed(), seed != viewModel.galaxySeed {
          viewModel.galaxySeed = seed
          _ = viewModel.prepareIfNeeded(for: proxy.size)
        }

        viewModel.onHighlightsPersisted = { entries in
          let indices = entries.compactMap { entry -> Int? in
            guard entry.id.hasPrefix("s-") else { return nil }
            return Int(entry.id.dropFirst(2))
          }
          if !indices.isEmpty {
            conversationStore.setPendingGalaxyStarIndices(indices, ttlSeconds: 1800)
          }
          Task { _ = await GalaxyHighlightsService.createHighlight(indices: indices) }
        }

        // App 启动/进入 Galaxy 时：拉取未过期 TapHighlight 并恢复高亮
        let remote = await GalaxyHighlightsService.fetchActiveHighlights()
        if !remote.isEmpty {
          _ = viewModel.prepareIfNeeded(for: proxy.size)
          for item in remote {
            viewModel.mergeTemporaryHighlights(indices: item.indices, expiresAt: item.expiresAt)
          }
        }

        updatePermanentStarHighlights(for: proxy.size)
      }
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

  private func updatePermanentStarHighlights(for size: CGSize) {
    _ = viewModel.prepareIfNeeded(for: size)
    let indices = starStore.constellation.stars
      .filter { !$0.isTemplate && !$0.isTransient }
      .compactMap(\.galaxyStarIndices)
      .flatMap { $0 }
    viewModel.setPermanentHighlights(indices: indices)
  }

  private func regionLabel(_ region: GalaxyRegion) -> String {
    switch region {
    case .emotion: return "情绪"
    case .relation: return "关系"
    case .growth: return "成长"
    }
  }
}
