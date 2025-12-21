import Foundation
import StarOracleCore

actor PersonalizedInspirationPrefetcher {
  static let shared = PersonalizedInspirationPrefetcher()

  private var cachedItems: [PersonalizedInspirationCandidate] = []
  private var cachedAt: Date?
  private var cachedUserId: String?
  private var inFlightTask: Task<[PersonalizedInspirationCandidate], Never>?

  private let ttl: TimeInterval = 10 * 60
  private let defaultCount: Int = 3

  func prefetchIfNeeded(userId: String?, force: Bool = false) async {
    guard SupabaseRuntime.loadConfig() != nil else { return }
    restoreFromCacheIfNeeded(userId: userId)

    if !force,
       let cachedAt,
       cachedItems.count >= defaultCount,
       Date().timeIntervalSince(cachedAt) < ttl {
      return
    }
    if inFlightTask != nil { return }

    let count = defaultCount
    let task = Task { await PersonalizedInspirationService.fetchCandidates(count: count) }
    inFlightTask = task
    let fetched = await task.value
    inFlightTask = nil

    guard !fetched.isEmpty else { return }
    cachedItems = Array(fetched.prefix(count))
    cachedAt = Date()
    cachedUserId = userId
    PersonalizedInspirationCache.save(
      .init(items: cachedItems, updatedAt: cachedAt ?? Date()),
      userId: userId
    )
  }

  func takeClonedItems(
    userId: String?,
    limit: Int = 3,
    newIdPrefix: String = "pi"
  ) -> [PersonalizedInspirationCandidate] {
    let resolvedLimit = max(0, min(5, limit))
    guard resolvedLimit > 0 else { return [] }
    restoreFromCacheIfNeeded(userId: userId)
    guard !cachedItems.isEmpty else { return [] }

    let prefixItems = cachedItems.prefix(resolvedLimit)
    return prefixItems.map { item in
      PersonalizedInspirationCandidate(
        id: "\(newIdPrefix)-\(UUID().uuidString.lowercased())",
        kind: item.kind,
        title: item.title,
        content: item.content,
        tags: item.tags,
        spawnedAt: item.spawnedAt
      )
    }
  }

  private func restoreFromCacheIfNeeded(userId: String?) {
    if cachedUserId == userId, !cachedItems.isEmpty { return }
    if cachedUserId != userId {
      cachedItems = []
      cachedAt = nil
      cachedUserId = userId
    }
    guard cachedItems.isEmpty else { return }
    guard let snapshot = PersonalizedInspirationCache.load(userId: userId) else { return }
    cachedItems = snapshot.items
    cachedAt = snapshot.updatedAt
  }
}

