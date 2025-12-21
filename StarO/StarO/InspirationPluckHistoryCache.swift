import Foundation

enum InspirationPluckHistoryCache {
  struct Snapshot: Codable, Equatable {
    var recentSourceIds: [String]
    var updatedAt: Date

    init(recentSourceIds: [String] = [], updatedAt: Date = Date()) {
      self.recentSourceIds = recentSourceIds
      self.updatedAt = updatedAt
    }
  }

  private static let queue = DispatchQueue(label: "staro.inspiration.pluck.history.cache")

  static func load(userId: String?) -> Snapshot? {
    queue.sync {
      let url = fileURL(userId: userId)
      guard let data = try? Data(contentsOf: url) else { return nil }
      do {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Snapshot.self, from: data)
      } catch {
        return nil
      }
    }
  }

  static func save(_ snapshot: Snapshot, userId: String?) {
    queue.async {
      let url = fileURL(userId: userId)
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
}

private extension InspirationPluckHistoryCache {
  static func fileURL(userId: String?) -> URL {
    let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
      ?? URL(fileURLWithPath: NSTemporaryDirectory())
    let raw = (userId ?? "anonymous").trimmingCharacters(in: .whitespacesAndNewlines)
    let safe = safeFileComponent(raw.isEmpty ? "anonymous" : raw)
    return dir.appendingPathComponent("inspiration_pluck_history_\(safe).json")
  }

  static func safeFileComponent(_ raw: String) -> String {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return "anonymous" }
    return trimmed.replacingOccurrences(
      of: "[^A-Za-z0-9_-]",
      with: "_",
      options: .regularExpression
    )
  }
}

