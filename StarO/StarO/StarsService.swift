import Foundation
import StarOracleCore

enum StarsService {
  struct StarRow: Decodable, Sendable {
    let id: String
    let chatId: String?
    let question: String?
    let answer: String?
    let summary: String?
    let tags: [String]?
    let galaxyStarIndices: [Int]?
    let primaryColorHex: String?
    let hapticPatternId: String?
    let insightLevel: Int?
    let createdAt: String?

    init(
      id: String,
      chatId: String?,
      question: String?,
      answer: String?,
      summary: String?,
      tags: [String]?,
      galaxyStarIndices: [Int]?,
      primaryColorHex: String?,
      hapticPatternId: String?,
      insightLevel: Int?,
      createdAt: String?
    ) {
      self.id = id
      self.chatId = chatId
      self.question = question
      self.answer = answer
      self.summary = summary
      self.tags = tags
      self.galaxyStarIndices = galaxyStarIndices
      self.primaryColorHex = primaryColorHex
      self.hapticPatternId = hapticPatternId
      self.insightLevel = insightLevel
      self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
      case id
      case chatId = "chat_id"
      case question
      case answer
      case summary
      case tags
      case galaxyStarIndices = "galaxy_star_indices"
      case primaryColorHex = "primary_color_hex"
      case hapticPatternId = "haptic_pattern_id"
      case insightLevel = "insight_level"
      case createdAt = "created_at"
    }
  }

  private static func parseISODate(_ raw: String?) -> Date? {
    guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
          !raw.isEmpty else { return nil }

    let withFraction = ISO8601DateFormatter()
    withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let parsed = withFraction.date(from: raw) { return parsed }

    let noFraction = ISO8601DateFormatter()
    noFraction.formatOptions = [.withInternetDateTime]
    return noFraction.date(from: raw)
  }

  static func fetchStars(limit: Int = 200) async -> [StarRow] {
    guard let config = SupabaseRuntime.loadConfig() else { return [] }

    let baseURL = config.url
      .appendingPathComponent("rest")
      .appendingPathComponent("v1")
      .appendingPathComponent("stars")

    guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return [] }
    components.queryItems = [
      .init(name: "select", value: "id,chat_id,question,answer,summary,tags,galaxy_star_indices,primary_color_hex,haptic_pattern_id,insight_level,created_at"),
      .init(name: "order", value: "created_at.desc"),
      .init(name: "limit", value: String(max(1, min(limit, 500))))
    ]
    guard let url = components.url else { return [] }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue(SupabaseRuntime.makeTraceId(), forHTTPHeaderField: SupabaseRuntime.HeaderName.traceId)
    if let anonKey = config.anonKey {
      request.setValue(anonKey, forHTTPHeaderField: "apikey")
    }
    request.setValue(SupabaseRuntime.authHeaderValue(for: config.jwt), forHTTPHeaderField: "Authorization")

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse else { return [] }
      guard (200..<300).contains(http.statusCode) else {
        let text = String(data: data, encoding: .utf8) ?? ""
        NSLog("⚠️ StarsService(list) | http=%d body=%@", http.statusCode, String(text.prefix(200)))
        return []
      }

      return try JSONDecoder().decode([StarRow].self, from: data)
    } catch {
      NSLog("⚠️ StarsService(list) | error=%@", error.localizedDescription)
      return []
    }
  }

  static func fetchStarByChatId(_ chatId: String) async -> StarRow? {
    guard let config = SupabaseRuntime.loadConfig() else { return nil }

    let baseURL = config.url
      .appendingPathComponent("rest")
      .appendingPathComponent("v1")
      .appendingPathComponent("stars")

    guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return nil }
    components.queryItems = [
      .init(name: "select", value: "id,chat_id,question,answer,summary,tags,galaxy_star_indices,primary_color_hex,haptic_pattern_id,insight_level,created_at"),
      .init(name: "chat_id", value: "eq.\(chatId)"),
      .init(name: "order", value: "created_at.desc"),
      .init(name: "limit", value: "1")
    ]
    guard let url = components.url else { return nil }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue(SupabaseRuntime.makeTraceId(), forHTTPHeaderField: SupabaseRuntime.HeaderName.traceId)
    if let anonKey = config.anonKey {
      request.setValue(anonKey, forHTTPHeaderField: "apikey")
    }
    request.setValue(SupabaseRuntime.authHeaderValue(for: config.jwt), forHTTPHeaderField: "Authorization")

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse else { return nil }
      guard (200..<300).contains(http.statusCode) else {
        let text = String(data: data, encoding: .utf8) ?? ""
        NSLog("⚠️ StarsService | http=%d body=%@", http.statusCode, String(text.prefix(200)))
        return nil
      }

      let decoded = try JSONDecoder().decode([StarRow].self, from: data)
      return decoded.first
    } catch {
      NSLog("⚠️ StarsService | error=%@", error.localizedDescription)
      return nil
    }
  }

  static func fetchStarById(_ starId: String) async -> StarRow? {
    guard let config = SupabaseRuntime.loadConfig() else { return nil }

    let baseURL = config.url
      .appendingPathComponent("rest")
      .appendingPathComponent("v1")
      .appendingPathComponent("stars")

    guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return nil }
    components.queryItems = [
      .init(name: "select", value: "id,chat_id,question,answer,summary,tags,galaxy_star_indices,primary_color_hex,haptic_pattern_id,insight_level,created_at"),
      .init(name: "id", value: "eq.\(starId)"),
      .init(name: "limit", value: "1")
    ]
    guard let url = components.url else { return nil }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue(SupabaseRuntime.makeTraceId(), forHTTPHeaderField: SupabaseRuntime.HeaderName.traceId)
    if let anonKey = config.anonKey {
      request.setValue(anonKey, forHTTPHeaderField: "apikey")
    }
    request.setValue(SupabaseRuntime.authHeaderValue(for: config.jwt), forHTTPHeaderField: "Authorization")

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse else { return nil }
      guard (200..<300).contains(http.statusCode) else {
        let text = String(data: data, encoding: .utf8) ?? ""
        NSLog("⚠️ StarsService(id) | http=%d body=%@", http.statusCode, String(text.prefix(200)))
        return nil
      }

      let decoded = try JSONDecoder().decode([StarRow].self, from: data)
      return decoded.first
    } catch {
      NSLog("⚠️ StarsService(id) | error=%@", error.localizedDescription)
      return nil
    }
  }

  static func toCoreStar(row: StarRow) -> Star {
    let level = max(1, min(5, row.insightLevel ?? 1))
    let id = row.id.trimmingCharacters(in: .whitespacesAndNewlines)
    let createdAt = parseISODate(row.createdAt) ?? Date()

    let x = stablePercent(seed: "x:\(id)")
    let y = stablePercent(seed: "y:\(id)")

    let isSpecial = level >= 4
    let size = 3.2 + Double(level) * 0.55
    let brightness = 0.55 + Double(level) * 0.08

    return Star(
      id: id,
      galaxyStarIndices: row.galaxyStarIndices,
      x: x,
      y: y,
      size: size,
      brightness: brightness,
      question: (row.question ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
      answer: (row.answer ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
      imageURL: nil,
      createdAt: createdAt,
      isSpecial: isSpecial,
      tags: row.tags ?? [],
      primaryCategory: "philosophy_and_existence",
      emotionalTone: [],
      questionType: nil,
      insightLevel: .init(value: level, description: insightLevelDescription(level)),
      initialLuminosity: Int(brightness * 100),
      connectionPotential: nil,
      suggestedFollowUp: nil,
      cardSummary: (row.summary ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
      similarity: nil,
      isTemplate: false,
      templateType: nil,
      isStreaming: false,
      isTransient: false
    )
  }

  private static func insightLevelDescription(_ level: Int) -> String {
    switch level {
    case 1: return "星辰"
    case 2: return "新星"
    case 3: return "恒星"
    case 4: return "超新星"
    case 5: return "白矮星"
    default: return "星辰"
    }
  }

  private static func stablePercent(seed: String) -> Double {
    let hash = fnv1a64(seed)
    let unit = Double(hash % 7000) / 100.0 // 0.00 ~ 69.99
    return 15.0 + unit
  }

  private static func fnv1a64(_ input: String) -> UInt64 {
    var hash: UInt64 = 14_695_981_039_346_656_037
    for byte in input.utf8 {
      hash ^= UInt64(byte)
      hash &*= 1_099_511_628_211
    }
    return hash
  }
}
