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
  @EnvironmentObject private var authService: AuthService
  @StateObject private var viewModel = GalaxyViewModel()

  @State private var lastTapRegion: GalaxyRegion?
  @State private var lastTapDate: Date = .distantPast
  @State private var debounceTask: Task<Void, Never>?
  @State private var didRestoreLocalGalaxyState: Bool = false
  @State private var cachedPermanentStarIndices: [Int] = []
  @State private var cachedTemporaryExpiresAtByIndex: [Int: Date] = [:]
  @State private var cachedUserId: String?
  var isTapEnabled: Bool = true

  var body: some View {
    GeometryReader { proxy in
      let topExcludedHeight = proxy.safeAreaInsets.top + 96
      GalaxyMetalContainer(
        viewModel: viewModel,
        size: proxy.size,
        onRegionSelected: nil,
        onTap: { point, size, region, timestamp in
          // 顶部菜单栏及周边区域：禁用银河点击，避免误触灵感卡片/高亮。
          guard point.y >= topExcludedHeight else { return }

          // 纯点击 Galaxy：每次点击都产生“临时高亮（TapHighlight）”，并上报后端做跨设备 1 天同步。
          let ttlExpiresAt = Date().addingTimeInterval(24 * 60 * 60)
          let highlightEntries = viewModel.triggerHighlight(
            at: point,
            in: size,
            tapTimestamp: timestamp,
            expiresAt: ttlExpiresAt,
            shouldPersist: true,
            hitTestRadius: 22
          )
          // 没有命中星点：不生成灵感卡片，避免“点空白也出卡”的误触。
          guard !highlightEntries.isEmpty else { return }

          // Cancel previous task to prevent card generation from previous rapid taps
          debounceTask?.cancel()

          // Lock UI during generation
          galaxyStore.setIsGeneratingCard(true)
          
          debounceTask = Task {
            // Wait for 120ms to allow rapid tapping (exploration)
            // Only the last tap will trigger the card generation AND the highlight
            try? await Task.sleep(nanoseconds: 120_000_000)
            
            guard !Task.isCancelled else { return }

            let xPct = Double(point.x / size.width) * 100.0
            let yPct = Double(point.y / size.height) * 100.0
            await MainActor.run {
              starStore.setIsAsking(false, position: StarPosition(x: xPct, y: yPct))
            }

            let shouldUseCloud = SupabaseRuntime.loadConfig() != nil && authService.isAuthenticated
            let userIdForCache = cachedUserId ?? resolvedCacheUserId()
            let cardIdForThisTap = UUID().uuidString.lowercased()
            let prefetchedCard: InspirationCard? = shouldUseCloud
              ? await InspirationCardPrefetcher.shared.takeClonedCard(
                withNewId: cardIdForThisTap,
                userId: userIdForCache
              )
              : nil
            let personalizedCandidates: [PersonalizedInspirationCandidate] = shouldUseCloud
              ? await PersonalizedInspirationPrefetcher.shared.takeClonedItems(
                userId: userIdForCache,
                limit: 3,
                newIdPrefix: "pi"
              )
              : []

            await MainActor.run {
              if let prefetchedCard {
                starStore.presentInspirationCard(prefetchedCard)
              } else {
                _ = starStore.drawInspirationCard(region: region)
              }
              starStore.setPersonalizedInspirationCandidates(personalizedCandidates)
              lastTapRegion = region
              lastTapDate = Date()

              // Unlock UI
              galaxyStore.setIsGeneratingCard(false)
            }

            // 预取下一张云端灵感卡：保证翻转时文本稳定，不在展示中途“热更新”卡片内容。
            if shouldUseCloud {
              Task.detached {
                await InspirationCardPrefetcher.shared.prefetchIfNeeded(userId: userIdForCache)
                await PersonalizedInspirationPrefetcher.shared.prefetchIfNeeded(userId: userIdForCache, force: true)
              }
            }
          }
        },
        isTapEnabled: isTapEnabled
      )
      .ignoresSafeArea()
      .task(id: proxy.size) {
        await MainActor.run {
          restoreLocalGalaxyStateIfNeeded(for: proxy.size)
          updatePermanentStarHighlights(for: proxy.size)
        }
      }
      .onChange(of: starStore.constellation.stars) { _, _ in
        updatePermanentStarHighlights(for: proxy.size)
      }
      .task(id: authService.hasRestoredSession) {
        viewModel.onHighlightsPersisted = { entries in
          let indices = entries.compactMap { entry -> Int? in
            guard entry.id.hasPrefix("s-") else { return nil }
            return Int(entry.id.dropFirst(2))
          }
          if !indices.isEmpty {
            conversationStore.setPendingGalaxyStarIndices(indices, ttlSeconds: 1800)
          }
          let expiresAt = Date().addingTimeInterval(24 * 60 * 60)
          upsertCachedTemporaryHighlights(indices: indices, expiresAt: expiresAt)
          Task { _ = await GalaxyHighlightsService.createHighlight(indices: indices) }
        }

        cachedUserId = resolvedCacheUserId()
        guard authService.hasRestoredSession,
              authService.isAuthenticated,
              SupabaseRuntime.loadConfig() != nil else {
          updatePermanentStarHighlights(for: proxy.size)
          return
        }

        Task.detached {
          await InspirationCardPrefetcher.shared.prefetchIfNeeded(userId: cachedUserId)
          await PersonalizedInspirationPrefetcher.shared.prefetchIfNeeded(userId: cachedUserId)
        }

        // T-102: Seed must be fetched from server as the single source of truth.
        if let seed = await GalaxySeedService.fetchSeed(), seed != viewModel.galaxySeed {
          viewModel.galaxySeed = seed
          _ = viewModel.prepareIfNeeded(for: proxy.size)
          applyCachedTemporaryHighlights()
          GalaxyStateCache.updateSeed(seed, userId: cachedUserId)
        }

        // App 启动/进入 Galaxy 时：拉取未过期 TapHighlight 并恢复高亮
        let remote = await GalaxyHighlightsService.fetchActiveHighlights()
        if !remote.isEmpty {
          _ = viewModel.prepareIfNeeded(for: proxy.size)
          for item in remote {
            viewModel.mergeTemporaryHighlights(indices: item.indices, expiresAt: item.expiresAt)
            for idx in item.indices where idx >= 0 {
              if let old = cachedTemporaryExpiresAtByIndex[idx] {
                cachedTemporaryExpiresAtByIndex[idx] = max(old, item.expiresAt)
              } else {
                cachedTemporaryExpiresAtByIndex[idx] = item.expiresAt
              }
            }
          }
          GalaxyStateCache.replaceTemporary(remote, userId: cachedUserId)
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
    let computed = starStore.constellation.stars
      .filter { !$0.isTemplate && !$0.isTransient }
      .compactMap(\.galaxyStarIndices)
      .flatMap { $0 }
    let computedIndices = Array(Set(computed.filter { $0 >= 0 })).sorted()
    let resolved = !computedIndices.isEmpty ? computedIndices : cachedPermanentStarIndices
    viewModel.setPermanentHighlights(indices: resolved)

    if !computedIndices.isEmpty, computedIndices != cachedPermanentStarIndices {
      cachedPermanentStarIndices = computedIndices
      GalaxyStateCache.updatePermanentIndices(computedIndices, userId: cachedUserId)
    }
  }

  private func restoreLocalGalaxyStateIfNeeded(for size: CGSize) {
    guard !didRestoreLocalGalaxyState else { return }
    cachedUserId = resolvedCacheUserId()
    guard let snapshot = GalaxyStateCache.load(userId: cachedUserId) else {
      didRestoreLocalGalaxyState = true
      return
    }

    if let seed = snapshot.seed, seed != viewModel.galaxySeed {
      viewModel.galaxySeed = seed
    }
    _ = viewModel.prepareIfNeeded(for: size)

    cachedPermanentStarIndices = snapshot.permanentIndices
    cachedTemporaryExpiresAtByIndex = snapshot.temporaryExpiresAtByIndex
    applyCachedTemporaryHighlights()
    if !cachedPermanentStarIndices.isEmpty {
      viewModel.setPermanentHighlights(indices: cachedPermanentStarIndices)
    }
    didRestoreLocalGalaxyState = true
  }

  private func resolvedCacheUserId() -> String? {
    let raw = AuthSessionStore.load()?.userId?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let raw, !raw.isEmpty { return raw }
    let email = authService.userEmail?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let email, !email.isEmpty { return email }
    return nil
  }

  private func applyCachedTemporaryHighlights() {
    guard !cachedTemporaryExpiresAtByIndex.isEmpty else { return }
    let grouped = Dictionary(grouping: cachedTemporaryExpiresAtByIndex.keys) { idx in
      cachedTemporaryExpiresAtByIndex[idx] ?? Date.distantPast
    }
    for (expiresAt, indices) in grouped {
      guard expiresAt > Date() else { continue }
      viewModel.mergeTemporaryHighlights(indices: indices, expiresAt: expiresAt)
    }
  }

  private func upsertCachedTemporaryHighlights(indices: [Int], expiresAt: Date) {
    guard !indices.isEmpty else { return }
    for idx in indices where idx >= 0 {
      if let old = cachedTemporaryExpiresAtByIndex[idx] {
        cachedTemporaryExpiresAtByIndex[idx] = max(old, expiresAt)
      } else {
        cachedTemporaryExpiresAtByIndex[idx] = expiresAt
      }
    }
    GalaxyStateCache.upsertTemporary(indices: indices, expiresAt: expiresAt, userId: cachedUserId)
  }

  private func regionLabel(_ region: GalaxyRegion) -> String {
    switch region {
    case .emotion: return "情绪"
    case .relation: return "关系"
    case .growth: return "成长"
    }
  }
}
