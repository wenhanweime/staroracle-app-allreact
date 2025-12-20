import Foundation

enum GalaxyStateCache {
  struct Snapshot: Codable, Equatable {
    var seed: UInt64?
    var permanentIndices: [Int]
    /// key = galaxy star index, value = expiresAt
    var temporaryExpiresAtByIndex: [Int: Date]
    var updatedAt: Date

    init(
      seed: UInt64? = nil,
      permanentIndices: [Int] = [],
      temporaryExpiresAtByIndex: [Int: Date] = [:],
      updatedAt: Date = Date()
    ) {
      self.seed = seed
      self.permanentIndices = permanentIndices
      self.temporaryExpiresAtByIndex = temporaryExpiresAtByIndex
      self.updatedAt = updatedAt
    }
  }

  private static let queue = DispatchQueue(label: "staro.galaxy.state.cache")

  static func load(userId: String?) -> Snapshot? {
    queue.sync {
      let url = fileURL(userId: userId)
      guard let data = try? Data(contentsOf: url) else { return nil }
      do {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Snapshot.self, from: data)
        // 读取时顺带做一次轻量清理（过期 TTL / 去重）
        return normalize(decoded)
      } catch {
        return nil
      }
    }
  }

  static func save(_ snapshot: Snapshot, userId: String?) {
    let normalized = normalize(snapshot)
    queue.async {
      let url = fileURL(userId: userId)
      do {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(normalized)
        try data.write(to: url, options: [.atomic])
      } catch {
        // best-effort
      }
    }
  }

  static func updateSeed(_ seed: UInt64, userId: String?) {
    upsert(userId: userId) { snapshot in
      snapshot.seed = seed
    }
  }

  static func updatePermanentIndices(_ indices: [Int], userId: String?) {
    upsert(userId: userId) { snapshot in
      snapshot.permanentIndices = normalizeIndices(indices)
    }
  }

  static func upsertTemporary(indices: [Int], expiresAt: Date, userId: String?) {
    guard !indices.isEmpty else { return }
    upsert(userId: userId) { snapshot in
      for idx in indices {
        if let old = snapshot.temporaryExpiresAtByIndex[idx] {
          snapshot.temporaryExpiresAtByIndex[idx] = max(old, expiresAt)
        } else {
          snapshot.temporaryExpiresAtByIndex[idx] = expiresAt
        }
      }
    }
  }

  static func replaceTemporary(_ list: [(indices: [Int], expiresAt: Date)], userId: String?) {
    upsert(userId: userId) { snapshot in
      var dict = snapshot.temporaryExpiresAtByIndex
      for item in list {
        for idx in item.indices {
          if let old = dict[idx] {
            dict[idx] = max(old, item.expiresAt)
          } else {
            dict[idx] = item.expiresAt
          }
        }
      }
      snapshot.temporaryExpiresAtByIndex = dict
    }
  }
}

private extension GalaxyStateCache {
  static func upsert(userId: String?, mutate: @escaping @Sendable (inout Snapshot) -> Void) {
    queue.async {
      let url = fileURL(userId: userId)
      var snapshot = Snapshot()
      if let data = try? Data(contentsOf: url) {
        do {
          let decoder = JSONDecoder()
          decoder.dateDecodingStrategy = .iso8601
          snapshot = try decoder.decode(Snapshot.self, from: data)
        } catch {
          snapshot = Snapshot()
        }
      }

      mutate(&snapshot)
      snapshot.updatedAt = Date()
      snapshot = normalize(snapshot)

      do {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        try data.write(to: url, options: [.atomic])
      } catch {
        // best-effort
      }
    }
  }

  static func normalize(_ snapshot: Snapshot) -> Snapshot {
    var result = snapshot
    result.permanentIndices = normalizeIndices(result.permanentIndices)

    let now = Date()
    result.temporaryExpiresAtByIndex = result.temporaryExpiresAtByIndex.filter { _, exp in
      exp > now
    }
    return result
  }

  static func normalizeIndices(_ indices: [Int]) -> [Int] {
    guard !indices.isEmpty else { return [] }
    let filtered = indices.filter { $0 >= 0 }
    return Array(Set(filtered)).sorted()
  }

  static func fileURL(userId: String?) -> URL {
    let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
      ?? URL(fileURLWithPath: NSTemporaryDirectory())
    let raw = (userId ?? "anonymous").trimmingCharacters(in: .whitespacesAndNewlines)
    let safe = safeFileComponent(raw.isEmpty ? "anonymous" : raw)
    return dir.appendingPathComponent("galaxy_state_\(safe).json")
  }

  static func safeFileComponent(_ raw: String) -> String {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return "anonymous" }
    return trimmed.replacingOccurrences(of: "[^A-Za-z0-9_-]", with: "_", options: .regularExpression)
  }
}
