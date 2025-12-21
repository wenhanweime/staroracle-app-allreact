import Foundation
import StarOracleCore

actor InspirationCardPrefetcher {
  static let shared = InspirationCardPrefetcher()

  private var cachedCards: [InspirationCard] = []
  private var cachedAt: Date?
  private var cachedUserId: String?
  private var inFlightTask: Task<[InspirationCard], Never>?

  private var recentSourceIds: [String] = []

  private let ttl: TimeInterval = 10 * 60
  private let desiredBufferCount: Int = 2
  private let recentLimit: Int = 24
  private let maxFetchAttempts: Int = 8

  func prefetchIfNeeded(userId: String?, force: Bool = false) async {
    guard SupabaseRuntime.loadConfig() != nil else { return }
    restoreHistoryIfNeeded(userId: userId)
    resetIfUserChanged(userId: userId)

    if !force,
       let cachedAt,
       cachedCards.count >= desiredBufferCount,
       Date().timeIntervalSince(cachedAt) < ttl {
      return
    }
    if inFlightTask != nil { return }

    let task = Task { await fetchCardsToFillBuffer() }
    inFlightTask = task
    let fetched = await task.value
    inFlightTask = nil

    guard !fetched.isEmpty else { return }
    cachedCards = fetched
    cachedAt = Date()
  }

  func takeClonedCard(withNewId newId: String, userId: String?) async -> InspirationCard? {
    let trimmedId = newId.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedId.isEmpty else { return nil }
    restoreHistoryIfNeeded(userId: userId)
    resetIfUserChanged(userId: userId)

    let card: InspirationCard? = {
      if !cachedCards.isEmpty {
        return cachedCards.removeFirst()
      }
      return nil
    }()

    if let card {
      recordServed(card: card, userId: userId)
      return cloned(card: card, newId: trimmedId)
    }

    if let fetched = await StarPluckService.pluckInspiration() {
      recordServed(card: fetched, userId: userId)
      return cloned(card: fetched, newId: trimmedId)
    }
    return nil
  }

  private func cloned(card: InspirationCard, newId: String) -> InspirationCard {
    return InspirationCard(
      id: newId,
      title: card.title,
      question: card.question,
      reflection: card.reflection,
      tags: card.tags,
      emotionalTone: card.emotionalTone,
      category: card.category,
      spawnedAt: card.spawnedAt
    )
  }

  private func resetIfUserChanged(userId: String?) {
    if cachedUserId == nil, userId == nil {
      return
    }
    if cachedUserId != userId {
      cachedUserId = userId
      cachedCards = []
      cachedAt = nil
      recentSourceIds = []
      if let snapshot = InspirationPluckHistoryCache.load(userId: userId) {
        recentSourceIds = snapshot.recentSourceIds
      }
    }
  }

  private func restoreHistoryIfNeeded(userId: String?) {
    if cachedUserId == userId, !recentSourceIds.isEmpty {
      return
    }
    if let snapshot = InspirationPluckHistoryCache.load(userId: userId) {
      recentSourceIds = snapshot.recentSourceIds
    }
  }

  private func fetchCardsToFillBuffer() async -> [InspirationCard] {
    var result = cachedCards

    let recent = Set(recentSourceIds)
    result = result.filter { card in
      let id = sourceId(from: card)
      return !id.isEmpty && !recent.contains(id)
    }

    var attempts = 0
    while result.count < desiredBufferCount, attempts < maxFetchAttempts {
      attempts += 1
      guard let fetched = await StarPluckService.pluckInspiration() else { continue }
      let id = sourceId(from: fetched)
      if id.isEmpty { continue }
      if recent.contains(id) { continue }
      if result.contains(where: { sourceId(from: $0) == id }) { continue }
      result.append(fetched)
    }
    return result
  }

  private func recordServed(card: InspirationCard, userId: String?) {
    let id = sourceId(from: card)
    guard !id.isEmpty else { return }

    recentSourceIds.removeAll(where: { $0 == id })
    recentSourceIds.insert(id, at: 0)
    if recentSourceIds.count > recentLimit {
      recentSourceIds = Array(recentSourceIds.prefix(recentLimit))
    }
    InspirationPluckHistoryCache.save(
      .init(recentSourceIds: recentSourceIds, updatedAt: Date()),
      userId: userId
    )
  }

  private func sourceId(from card: InspirationCard) -> String {
    if let tag = card.tags.first(where: { $0.hasPrefix("source_id:") }) {
      return String(tag.dropFirst("source_id:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return card.id.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
