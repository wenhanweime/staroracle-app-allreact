import Foundation

enum UserMemoryRefreshService {
  struct Cursor: Decodable, Sendable {
    let lastMessageAt: String?
    let lastMessageId: String?
    let lastChatId: String?

    enum CodingKeys: String, CodingKey {
      case lastMessageAt = "last_message_at"
      case lastMessageId = "last_message_id"
      case lastChatId = "last_chat_id"
    }
  }

  struct Result: Decodable, Sendable {
    let ok: Bool?
    let updated: Bool?
    let reason: String?
    let processedMessages: Int?
    let approxTokens: Int?
    let cursor: Cursor?
    let traceId: String?
    let code: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
      case ok
      case updated
      case reason
      case processedMessages = "processed_messages"
      case approxTokens = "approx_tokens"
      case cursor
      case traceId = "trace_id"
      case code
      case message
    }
  }

  private struct ErrorResponse: Decodable {
    let ok: Bool?
    let code: String?
    let message: String?
    let trace_id: String?
  }

  enum RefreshError: LocalizedError {
    case missingConfig
    case invalidResponse
    case http(status: Int, code: String, message: String)
    case cancelled

    var errorDescription: String? {
      switch self {
      case .missingConfig:
        return "未配置 SUPABASE_URL + TOKEN/SUPABASE_JWT"
      case .invalidResponse:
        return "user-memory-refresh 响应无效"
      case let .http(status, code, message):
        return "user-memory-refresh 请求失败(\(status))：\(code) \(message)"
      case .cancelled:
        return "请求已取消"
      }
    }
  }

  static func refresh(
    force: Bool = true,
    maxMessages: Int? = nil,
    traceId: String? = nil
  ) async throws -> Result {
    let config = try await SupabaseRuntime.loadConfigRefreshingIfNeeded()

    let url = config.url
      .appendingPathComponent("functions")
      .appendingPathComponent("v1")
      .appendingPathComponent("user-memory-refresh")

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(traceId ?? SupabaseRuntime.makeTraceId(), forHTTPHeaderField: SupabaseRuntime.HeaderName.traceId)
    if let anonKey = config.anonKey {
      request.setValue(anonKey, forHTTPHeaderField: "apikey")
    }
    request.setValue(SupabaseRuntime.authHeaderValue(for: config.jwt), forHTTPHeaderField: "Authorization")

    var body: [String: Any] = ["force": force]
    if let maxMessages {
      body["max_messages"] = maxMessages
    }
    request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse else {
        throw RefreshError.invalidResponse
      }

      if (200..<300).contains(http.statusCode) {
        let decoded = try JSONDecoder().decode(Result.self, from: data)
        return decoded
      }

      if let decoded = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
        throw RefreshError.http(
          status: http.statusCode,
          code: decoded.code ?? "UM99",
          message: decoded.message ?? "unknown"
        )
      }

      let text = String(data: data, encoding: .utf8) ?? ""
      throw RefreshError.http(status: http.statusCode, code: "UM99", message: String(text.prefix(200)))
    } catch is CancellationError {
      throw RefreshError.cancelled
    } catch let error as SupabaseRuntime.SessionError {
      switch error {
      case .missingProjectConfig, .missingSession:
        throw RefreshError.missingConfig
      default:
        throw error
      }
    }
  }
}

