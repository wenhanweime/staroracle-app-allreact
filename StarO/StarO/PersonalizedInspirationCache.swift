import Foundation
import StarOracleCore

enum PersonalizedInspirationCache {
  struct Snapshot: Codable, Equatable {
    var items: [PersonalizedInspirationCandidate]
    var updatedAt: Date

    init(items: [PersonalizedInspirationCandidate] = [], updatedAt: Date = Date()) {
      self.items = items
      self.updatedAt = updatedAt
    }
  }

  private static let queue = DispatchQueue(label: "staro.personalized.inspiration.cache")

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

private extension PersonalizedInspirationCache {
  static func fileURL(userId: String?) -> URL {
    let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
      ?? URL(fileURLWithPath: NSTemporaryDirectory())
    let raw = (userId ?? "anonymous").trimmingCharacters(in: .whitespacesAndNewlines)
    let safe = safeFileComponent(raw.isEmpty ? "anonymous" : raw)
    return dir.appendingPathComponent("personalized_inspiration_\(safe).json")
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

