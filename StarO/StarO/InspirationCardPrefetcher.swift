import Foundation
import StarOracleCore

actor InspirationCardPrefetcher {
  static let shared = InspirationCardPrefetcher()

  private var cachedCard: InspirationCard?
  private var cachedAt: Date?
  private var inFlightTask: Task<InspirationCard?, Never>?

  private let ttl: TimeInterval = 10 * 60

  func prefetchIfNeeded(force: Bool = false) async {
    guard SupabaseRuntime.loadConfig() != nil else { return }
    if !force,
       let cachedAt,
       let cachedCard,
       Date().timeIntervalSince(cachedAt) < ttl,
       !cachedCard.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return
    }
    if inFlightTask != nil { return }

    let task = Task { await StarPluckService.pluckInspiration() }
    inFlightTask = task
    let fetched = await task.value
    inFlightTask = nil

    guard let fetched else { return }
    cachedCard = fetched
    cachedAt = Date()
  }

  func takeClonedCard(withNewId newId: String) -> InspirationCard? {
    let trimmedId = newId.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedId.isEmpty else { return nil }
    guard let card = cachedCard else { return nil }
    cachedCard = nil
    cachedAt = nil

    return InspirationCard(
      id: trimmedId,
      title: card.title,
      question: card.question,
      reflection: card.reflection,
      tags: card.tags,
      emotionalTone: card.emotionalTone,
      category: card.category,
      spawnedAt: card.spawnedAt
    )
  }
}

