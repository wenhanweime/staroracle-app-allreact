import Foundation
import StarOracleCore

enum StarService {
  struct CastResult: Decodable, Sendable {
    let ok: Bool?
    let coordX: Double?
    let coordY: Double?
    let coordZ: Double?
    let galaxyStarIndices: [Int]?
    let traceId: String?
    let code: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
      case ok
      case coordX = "coord_x"
      case coordY = "coord_y"
      case coordZ = "coord_z"
      case galaxyStarIndices = "galaxy_star_indices"
      case traceId = "trace_id"
      case code
      case message
    }
  }

  struct ReviewResult: Decodable, Sendable {
    struct ReviewContent: Decodable, Sendable {
      let id: String?
      let question: String?
      let answer: String?
      let summary: String?
      let tags: [String]?
      let galaxyStarIndices: [Int]?
      let primaryColorHex: String?
      let hapticPatternId: String?
      let insightLevel: Int?
      let createdAt: String?

      enum CodingKeys: String, CodingKey {
        case id
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

    let type: String?
    let content: ReviewContent?
    let traceId: String?
    let code: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
      case type
      case content
      case traceId = "trace_id"
      case code
      case message
    }
  }

  enum StarServiceError: LocalizedError {
    case missingConfig
    case invalidResponse
    case http(status: Int, code: String, message: String)
    case cancelled

    var errorDescription: String? {
      switch self {
      case .missingConfig:
        return "未配置 SUPABASE_URL + TOKEN/SUPABASE_JWT"
      case .invalidResponse:
        return "服务响应无效"
      case let .http(status, code, message):
        return "请求失败(\(status))：\(code) \(message)"
      case .cancelled:
        return "请求已取消"
      }
    }
  }

  static func castStar(
    chatId: String,
    x: Double? = nil,
    y: Double? = nil,
    region: String? = nil,
    galaxyStarIndices: [Int]? = nil,
    traceId: String? = nil
  ) async throws -> CastResult {
    guard let config = SupabaseRuntime.loadConfig() else {
      throw StarServiceError.missingConfig
    }

    let url = config.url
      .appendingPathComponent("functions")
      .appendingPathComponent("v1")
      .appendingPathComponent("star-cast")

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(traceId ?? SupabaseRuntime.makeTraceId(), forHTTPHeaderField: SupabaseRuntime.HeaderName.traceId)
    if let anonKey = config.anonKey {
      request.setValue(anonKey, forHTTPHeaderField: "apikey")
    }
    request.setValue(SupabaseRuntime.authHeaderValue(for: config.jwt), forHTTPHeaderField: "Authorization")

    var body: [String: Any] = ["chat_id": chatId]
    if let x, let y, x.isFinite, y.isFinite {
      body["x"] = x
      body["y"] = y
    }
    if let region, !region.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      body["region"] = region
    }
    if let galaxyStarIndices, !galaxyStarIndices.isEmpty {
      body["galaxy_star_indices"] = galaxyStarIndices
    }
    request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse else {
        throw StarServiceError.invalidResponse
      }
      let decoded = try JSONDecoder().decode(CastResult.self, from: data)
      guard (200..<300).contains(http.statusCode) else {
        throw StarServiceError.http(status: http.statusCode, code: decoded.code ?? "ST99", message: decoded.message ?? "unknown")
      }
      return decoded
    } catch is CancellationError {
      throw StarServiceError.cancelled
    }
  }

  static func pluckInspiration(tag: String? = nil) async -> InspirationCard? {
    await StarPluckService.pluckInspiration(tag: tag)
  }

  static func pluckReview(tag: String? = nil, before: Date? = nil, traceId: String? = nil) async -> Star? {
    guard let config = SupabaseRuntime.loadConfig() else {
      NSLog("ℹ️ StarService.pluckReview | missing SUPABASE_URL + TOKEN/SUPABASE_JWT")
      return nil
    }

    let url = config.url
      .appendingPathComponent("functions")
      .appendingPathComponent("v1")
      .appendingPathComponent("star-pluck")

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(traceId ?? SupabaseRuntime.makeTraceId(), forHTTPHeaderField: SupabaseRuntime.HeaderName.traceId)
    if let anonKey = config.anonKey {
      request.setValue(anonKey, forHTTPHeaderField: "apikey")
    }
    request.setValue(SupabaseRuntime.authHeaderValue(for: config.jwt), forHTTPHeaderField: "Authorization")

    var body: [String: Any] = ["mode": "review"]
    if let tag, !tag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      body["tag"] = tag
    }
    if let before {
      body["before"] = ISO8601DateFormatter().string(from: before)
    }

    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse else { return nil }
      guard (200..<300).contains(http.statusCode) else {
        if let decoded = try? JSONDecoder().decode(ReviewResult.self, from: data) {
          NSLog(
            "⚠️ StarService.pluckReview | http=%d code=%@ message=%@",
            http.statusCode,
            decoded.code ?? "PL99",
            decoded.message ?? "unknown"
          )
          return nil
        }
        let text = String(data: data, encoding: .utf8) ?? ""
        NSLog("⚠️ StarService.pluckReview | http=%d body=%@", http.statusCode, String(text.prefix(200)))
        return nil
      }

      let decoded = try JSONDecoder().decode(ReviewResult.self, from: data)
      guard decoded.type == "review", let content = decoded.content else { return nil }

      let row = StarsService.StarRow(
        id: content.id ?? UUID().uuidString,
        chatId: nil,
        question: content.question,
        answer: content.answer,
        summary: content.summary,
        tags: content.tags,
        galaxyStarIndices: content.galaxyStarIndices,
        primaryColorHex: content.primaryColorHex,
        hapticPatternId: content.hapticPatternId,
        insightLevel: content.insightLevel,
        createdAt: content.createdAt
      )
      return StarsService.toCoreStar(row: row)
    } catch {
      NSLog("⚠️ StarService.pluckReview | error=%@", error.localizedDescription)
      return nil
    }
  }
}

