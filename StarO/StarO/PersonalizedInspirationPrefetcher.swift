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

    if inFlightTask != nil { return }

    let now = Date()
    let isExpired: Bool = {
      guard let cachedAt else { return true }
      return now.timeIntervalSince(cachedAt) >= ttl
    }()

    let missing = max(0, defaultCount - cachedItems.count)
    if !force, !isExpired, missing == 0 {
      return
    }

    let countToFetch: Int = {
      if force || isExpired { return defaultCount }
      return max(1, min(5, missing))
    }()

    let task = Task { await PersonalizedInspirationService.fetchCandidates(count: countToFetch) }
    inFlightTask = task
    let fetched = await task.value
    inFlightTask = nil

    guard !fetched.isEmpty else { return }

    var next: [PersonalizedInspirationCandidate] = []
    next.reserveCapacity(max(defaultCount, cachedItems.count))
    if !isExpired, !force {
      next.append(contentsOf: cachedItems)
    }

    for item in fetched {
      let key = normalizedKey(for: item)
      if key.isEmpty { continue }
      if next.contains(where: { normalizedKey(for: $0) == key }) { continue }
      next.append(item)
      if next.count >= defaultCount { break }
    }

    if next.isEmpty {
      return
    }

    cachedItems = next
    cachedAt = now
    cachedUserId = userId
    PersonalizedInspirationCache.save(
      .init(items: cachedItems, updatedAt: cachedAt ?? Date()),
      userId: userId
    )
  }

  func takeNextClonedItem(
    userId: String?,
    newIdPrefix: String = "pi"
  ) -> PersonalizedInspirationCandidate? {
    restoreFromCacheIfNeeded(userId: userId)
    guard !cachedItems.isEmpty else { return nil }

    let item = cachedItems.removeFirst()
    let resolvedId = "\(newIdPrefix)-\(UUID().uuidString.lowercased())"
    cachedAt = cachedAt ?? Date()
    cachedUserId = userId
    PersonalizedInspirationCache.save(
      .init(items: cachedItems, updatedAt: cachedAt ?? Date()),
      userId: userId
    )

    return PersonalizedInspirationCandidate(
      id: resolvedId,
      kind: item.kind,
      title: item.title,
      content: item.content,
      tags: item.tags,
      spawnedAt: item.spawnedAt
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

  private func normalizedKey(for item: PersonalizedInspirationCandidate) -> String {
    let kind = item.kind.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
    let content = item.content.trimmingCharacters(in: .whitespacesAndNewlines)
    if kind.isEmpty || (title.isEmpty && content.isEmpty) { return "" }
    return "\(kind)|\(title)|\(content)"
  }
}
