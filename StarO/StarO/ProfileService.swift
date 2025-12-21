import Foundation

enum ProfileService {
  struct User: Codable, Sendable {
    let id: String?
    let email: String?
  }

  struct Profile: Codable, Sendable {
    let displayName: String?
    let avatarEmoji: String?
    let avatarUrl: String?
    let galaxySeed: String?
    let createdAt: String?
    let preferredModelId: String?
    let longTermMemoryPrompt: String?
    let longTermMemoryUpdatedAt: String?
    let longTermMemoryLastMessageAt: String?

    enum CodingKeys: String, CodingKey {
      case displayName = "display_name"
      case avatarEmoji = "avatar_emoji"
      case avatarUrl = "avatar_url"
      case galaxySeed = "galaxy_seed"
      case createdAt = "created_at"
      case preferredModelId = "preferred_model_id"
      case longTermMemoryPrompt = "long_term_memory_prompt"
      case longTermMemoryUpdatedAt = "long_term_memory_updated_at"
      case longTermMemoryLastMessageAt = "long_term_memory_last_message_at"
    }
  }

  struct Stats: Codable, Sendable {
    let starsCount: Int?
    let chatsCount: Int?

    enum CodingKeys: String, CodingKey {
      case starsCount = "stars_count"
      case chatsCount = "chats_count"
    }
  }

  private struct GetProfileResponse: Decodable {
    let ok: Bool?
    let user: User?
    let profile: Profile?
    let stats: Stats?
    let trace_id: String?
    let code: String?
    let message: String?
  }

  private struct UpdateProfileResponse: Decodable {
    let ok: Bool?
    let user: User?
    let profile: Profile?
    let trace_id: String?
    let code: String?
    let message: String?
  }

  private struct ErrorResponse: Decodable {
    let ok: Bool?
    let code: String?
    let message: String?
    let trace_id: String?
  }

  enum ProfileError: LocalizedError {
    case missingConfig
    case invalidResponse
    case http(status: Int, code: String, message: String)
    case cancelled

    var errorDescription: String? {
      switch self {
      case .missingConfig:
        return "未配置 SUPABASE_URL + TOKEN/SUPABASE_JWT"
      case .invalidResponse:
        return "profile 响应无效"
      case let .http(status, code, message):
        return "profile 请求失败(\(status))：\(code) \(message)"
      case .cancelled:
        return "请求已取消"
      }
    }
  }

  static func getProfile(traceId: String? = nil) async throws -> (user: User, profile: Profile, stats: Stats?) {
    guard let config = SupabaseRuntime.loadConfig() else {
      throw ProfileError.missingConfig
    }

    let url = config.url
      .appendingPathComponent("functions")
      .appendingPathComponent("v1")
      .appendingPathComponent("get-profile")

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue(traceId ?? SupabaseRuntime.makeTraceId(), forHTTPHeaderField: SupabaseRuntime.HeaderName.traceId)
    if let anonKey = config.anonKey {
      request.setValue(anonKey, forHTTPHeaderField: "apikey")
    }
    request.setValue(SupabaseRuntime.authHeaderValue(for: config.jwt), forHTTPHeaderField: "Authorization")

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse else {
        throw ProfileError.invalidResponse
      }

      if (200..<300).contains(http.statusCode) {
        let decoded = try JSONDecoder().decode(GetProfileResponse.self, from: data)
        guard let user = decoded.user, let profile = decoded.profile else {
          throw ProfileError.invalidResponse
        }
        return (user: user, profile: profile, stats: decoded.stats)
      }

      if let decoded = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
        throw ProfileError.http(
          status: http.statusCode,
          code: decoded.code ?? "PF99",
          message: decoded.message ?? "unknown"
        )
      }

      let text = String(data: data, encoding: .utf8) ?? ""
      throw ProfileError.http(status: http.statusCode, code: "PF99", message: String(text.prefix(200)))
    } catch is CancellationError {
      throw ProfileError.cancelled
    }
  }

  static func updateProfile(
    displayName: String?,
    avatarEmoji: String?,
    avatarUrl: String? = nil,
    preferredModelId: String? = nil,
    traceId: String? = nil
  ) async throws -> (user: User, profile: Profile) {
    guard let config = SupabaseRuntime.loadConfig() else {
      throw ProfileError.missingConfig
    }

    let url = config.url
      .appendingPathComponent("functions")
      .appendingPathComponent("v1")
      .appendingPathComponent("update-profile")

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(traceId ?? SupabaseRuntime.makeTraceId(), forHTTPHeaderField: SupabaseRuntime.HeaderName.traceId)
    if let anonKey = config.anonKey {
      request.setValue(anonKey, forHTTPHeaderField: "apikey")
    }
    request.setValue(SupabaseRuntime.authHeaderValue(for: config.jwt), forHTTPHeaderField: "Authorization")

    var body: [String: Any] = [:]
    if let displayName {
      body["display_name"] = displayName
    }
    if let avatarEmoji {
      body["avatar_emoji"] = avatarEmoji
    }
    if let avatarUrl {
      body["avatar_url"] = avatarUrl
    }
    if let preferredModelId {
      body["preferred_model_id"] = preferredModelId
    }
    request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse else {
        throw ProfileError.invalidResponse
      }

      if (200..<300).contains(http.statusCode) {
        let decoded = try JSONDecoder().decode(UpdateProfileResponse.self, from: data)
        guard let user = decoded.user, let profile = decoded.profile else {
          throw ProfileError.invalidResponse
        }
        return (user: user, profile: profile)
      }

      if let decoded = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
        throw ProfileError.http(
          status: http.statusCode,
          code: decoded.code ?? "PU99",
          message: decoded.message ?? "unknown"
        )
      }

      let text = String(data: data, encoding: .utf8) ?? ""
      throw ProfileError.http(status: http.statusCode, code: "PU99", message: String(text.prefix(200)))
    } catch is CancellationError {
      throw ProfileError.cancelled
    }
  }
}
