import Foundation

@MainActor
enum ChatMessageInsertService {
  enum InsertError: LocalizedError {
    case missingConfig
    case invalidChatId
    case invalidContent
    case missingUserId
    case invalidResponse
    case http(status: Int, body: String)

    var errorDescription: String? {
      switch self {
      case .missingConfig:
        return "未配置 SUPABASE_URL + TOKEN/SUPABASE_JWT"
      case .invalidChatId:
        return "chat_id 无效"
      case .invalidContent:
        return "content 无效"
      case .missingUserId:
        return "未能解析用户身份（user_id）"
      case .invalidResponse:
        return "写入消息响应无效"
      case let .http(status, body):
        return "写入消息失败(\(status))：\(body)"
      }
    }
  }

  static func insertSystemMessage(chatId: String, content: String) async throws {
    let trimmedChatId = chatId.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedChatId.isEmpty else { throw InsertError.invalidChatId }

    let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedContent.isEmpty else { throw InsertError.invalidContent }

    let config: SupabaseRuntime.Config
    do {
      config = try await SupabaseRuntime.loadConfigRefreshingIfNeeded()
    } catch let error as SupabaseRuntime.SessionError {
      if case .missingProjectConfig = error {
        throw InsertError.missingConfig
      }
      throw error
    }

    let userId =
      AuthSessionStore.load()?.userId ??
      userIdFromJWT(config.jwt)
    guard let userId, !userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw InsertError.missingUserId
    }

    let baseURL = config.url
      .appendingPathComponent("rest")
      .appendingPathComponent("v1")
      .appendingPathComponent("messages")

    guard let url = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)?.url else {
      throw InsertError.invalidResponse
    }

    var row: [String: Any] = [
      "chat_id": trimmedChatId,
      "user_id": userId,
      "role": "system",
      "content": trimmedContent
    ]
    row["token_count"] = estimateTokenCount(trimmedContent)

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(SupabaseRuntime.makeTraceId(), forHTTPHeaderField: SupabaseRuntime.HeaderName.traceId)
    request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
    if let anonKey = config.anonKey {
      request.setValue(anonKey, forHTTPHeaderField: "apikey")
    }
    request.setValue(SupabaseRuntime.authHeaderValue(for: config.jwt), forHTTPHeaderField: "Authorization")
    request.httpBody = try JSONSerialization.data(withJSONObject: [row], options: [])

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse else { throw InsertError.invalidResponse }
    guard (200..<300).contains(http.statusCode) else {
      let text = String(data: data, encoding: .utf8) ?? ""
      throw InsertError.http(status: http.statusCode, body: String(text.prefix(200)))
    }
  }

  private static func estimateTokenCount(_ text: String) -> Int {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return 0 }
    let bytes = trimmed.lengthOfBytes(using: .utf8)
    return max(1, Int(ceil(Double(bytes) / 4.0)))
  }

  private static func userIdFromJWT(_ jwt: String) -> String? {
    let trimmed = jwt.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    let normalized = trimmed.lowercased().hasPrefix("bearer ") ? String(trimmed.dropFirst(7)) : trimmed
    let parts = normalized.split(separator: ".")
    guard parts.count >= 2 else { return nil }
    let payloadPart = String(parts[1])
    guard let data = decodeBase64URL(payloadPart) else { return nil }
    guard
      let json = try? JSONSerialization.jsonObject(with: data, options: []),
      let dict = json as? [String: Any]
    else {
      return nil
    }
    let sub = (dict["sub"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    return (sub?.isEmpty == false) ? sub : nil
  }

  private static func decodeBase64URL(_ input: String) -> Data? {
    var value = input.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    let remainder = value.count % 4
    if remainder != 0 {
      value.append(String(repeating: "=", count: 4 - remainder))
    }
    return Data(base64Encoded: value)
  }
}

