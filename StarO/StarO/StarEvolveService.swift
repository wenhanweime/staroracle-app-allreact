import Foundation

enum StarEvolveService {
  struct Energy: Decodable, Sendable {
    let day: String?
    let remaining: Int?
  }

  struct Star: Decodable, Sendable {
    let id: String?
    let insight_level: Int?
    let evolution_status: String?
    let review_count: Int?
    let reflection_count: Int?
    let has_nebula: Bool?
    let created_at: String?
  }

  struct SuccessResponse: Decodable, Sendable {
    let ok: Bool?
    let changed: Bool?
    let star: Star?
    let energy: Energy?
    let trace_id: String?
  }

  private struct ErrorResponse: Decodable {
    let ok: Bool?
    let code: String?
    let message: String?
    let trace_id: String?
    let energy: Energy?
  }

  enum EvolveError: LocalizedError {
    case missingConfig
    case invalidResponse
    case http(status: Int, code: String, message: String, energy: Energy?)
    case cancelled

    var errorDescription: String? {
      switch self {
      case .missingConfig:
        return "未配置 SUPABASE_URL + TOKEN/SUPABASE_JWT"
      case .invalidResponse:
        return "star-evolve 响应无效"
      case let .http(status, code, message, _):
        return "star-evolve 请求失败(\(status))：\(code) \(message)"
      case .cancelled:
        return "请求已取消"
      }
    }
  }

  static func upgradeByButton(starId: String, traceId: String? = nil) async throws -> SuccessResponse {
    try await evolve(starId: starId, action: "upgrade_button", traceId: traceId)
  }

  static func evolve(starId: String, action: String? = nil, traceId: String? = nil) async throws -> SuccessResponse {
    guard let config = SupabaseRuntime.loadConfig() else {
      throw EvolveError.missingConfig
    }

    let url = config.url
      .appendingPathComponent("functions")
      .appendingPathComponent("v1")
      .appendingPathComponent("star-evolve")

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(traceId ?? SupabaseRuntime.makeTraceId(), forHTTPHeaderField: SupabaseRuntime.HeaderName.traceId)
    if let anonKey = config.anonKey {
      request.setValue(anonKey, forHTTPHeaderField: "apikey")
    }
    request.setValue(SupabaseRuntime.authHeaderValue(for: config.jwt), forHTTPHeaderField: "Authorization")

    var body: [String: Any] = ["star_id": starId]
    if let action, !action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      body["action"] = action
    }
    request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse else {
        throw EvolveError.invalidResponse
      }

      if (200..<300).contains(http.statusCode) {
        let decoded = try JSONDecoder().decode(SuccessResponse.self, from: data)
        return decoded
      }

      if let decoded = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
        throw EvolveError.http(
          status: http.statusCode,
          code: decoded.code ?? "EV99",
          message: decoded.message ?? "unknown",
          energy: decoded.energy
        )
      }

      let text = String(data: data, encoding: .utf8) ?? ""
      throw EvolveError.http(status: http.statusCode, code: "EV99", message: String(text.prefix(200)), energy: nil)
    } catch is CancellationError {
      throw EvolveError.cancelled
    }
  }
}

