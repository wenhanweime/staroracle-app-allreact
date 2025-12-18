import Foundation

enum ChatSendService {
  enum StreamEvent: Sendable {
    case delta(String)
    case done(messageId: String?, chatId: String, traceId: String?)
  }

  struct DeltaPayload: Decodable {
    let text: String?
    let trace_id: String?
  }

  struct DonePayload: Decodable {
    let message_id: String?
    let chat_id: String?
    let trace_id: String?
  }

  struct ErrorPayload: Decodable {
    let code: String?
    let message: String?
    let trace_id: String?
  }

  enum ChatSendError: LocalizedError {
    case missingConfig
    case invalidResponse
    case http(status: Int, body: String)
    case server(code: String, message: String)
    case cancelled

    var errorDescription: String? {
      switch self {
      case .missingConfig:
        return "未配置 SUPABASE_URL + TOKEN/SUPABASE_JWT"
      case .invalidResponse:
        return "chat-send 响应无效"
      case let .http(status, body):
        return "chat-send 请求失败(\(status))：\(body)"
      case let .server(code, message):
        return "\(code)：\(message)"
      case .cancelled:
        return "请求已取消"
      }
    }
  }

  static func streamMessage(
    chatId: String,
    message: String,
    traceId: String? = nil,
    idempotencyKey: String? = nil,
    galaxyStarIndices: [Int]? = nil,
    reviewSessionId: String? = nil
  ) -> AsyncThrowingStream<StreamEvent, Error> {
    AsyncThrowingStream { continuation in
      let task = Task {
        do {
          let config = try await SupabaseRuntime.loadConfigRefreshingIfNeeded()

          let url = config.url
            .appendingPathComponent("functions")
            .appendingPathComponent("v1")
            .appendingPathComponent("chat-send")

          let requestTraceId = (traceId?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
            ?? SupabaseRuntime.makeTraceId()
          let requestIdempotencyKey = (idempotencyKey?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
            ?? SupabaseRuntime.makeIdempotencyKey()

          NSLog(
            "🌐 ChatSendService | POST %@ chat_id=%@ message_len=%d trace_id=%@ idem=%@",
            url.absoluteString,
            chatId,
            message.count,
            requestTraceId,
            requestIdempotencyKey
          )

          var request = URLRequest(url: url)
          request.httpMethod = "POST"
          request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
          request.setValue("application/json", forHTTPHeaderField: "Content-Type")
          request.setValue(requestTraceId, forHTTPHeaderField: SupabaseRuntime.HeaderName.traceId)
          request.setValue(requestIdempotencyKey, forHTTPHeaderField: SupabaseRuntime.HeaderName.idempotencyKey)
          if let anonKey = config.anonKey {
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
          }
          request.setValue(SupabaseRuntime.authHeaderValue(for: config.jwt), forHTTPHeaderField: "Authorization")

          var body: [String: Any] = [
            "chat_id": chatId,
            "message": message,
            "idempotency_key": requestIdempotencyKey
          ]
          if let reviewSessionId, !reviewSessionId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            body["review_session_id"] = reviewSessionId
          }
          if let galaxyStarIndices, !galaxyStarIndices.isEmpty {
            body["galaxy_star_indices"] = galaxyStarIndices
          }

          request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

          let (bytes, response) = try await URLSession.shared.bytes(for: request)
          guard let http = response as? HTTPURLResponse else {
            throw ChatSendError.invalidResponse
          }
          guard (200..<300).contains(http.statusCode) else {
            let raw = try await bytes.reduce(into: [UInt8]()) { $0.append($1) }
            let text = String(data: Data(raw), encoding: .utf8) ?? ""
            throw ChatSendError.http(status: http.statusCode, body: String(text.prefix(200)))
          }

          var currentEvent: String?
          var dataLines: [String] = []
          var didReceiveDone = false
          var didYieldDelta = false
          var pendingDone: (messageId: String?, chatId: String, traceId: String?)?

          func dispatchEventIfNeeded() throws {
            guard !dataLines.isEmpty else {
              currentEvent = nil
              return
            }
            let eventName = (currentEvent ?? "message").trimmingCharacters(in: .whitespacesAndNewlines)
            let payload = dataLines.joined(separator: "\n")
            dataLines.removeAll(keepingCapacity: true)
            currentEvent = nil

            guard let data = payload.data(using: .utf8) else { return }

            switch eventName {
            case "delta":
              if let decoded = try? JSONDecoder().decode(DeltaPayload.self, from: data),
                 let text = decoded.text, !text.isEmpty {
                continuation.yield(.delta(text))
                didYieldDelta = true
              }
            case "done":
              if let decoded = try? JSONDecoder().decode(DonePayload.self, from: data) {
                let resolvedChatId = (decoded.chat_id?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
                  ?? chatId
                if !resolvedChatId.isEmpty {
                  NSLog("✅ ChatSendService | done chat_id=%@ message_id=%@ trace_id=%@", resolvedChatId, decoded.message_id ?? "nil", decoded.trace_id ?? "nil")
                  if let serverTrace = decoded.trace_id,
                     !serverTrace.isEmpty,
                     serverTrace != requestTraceId {
                    NSLog("⚠️ ChatSendService | trace_id mismatch request=%@ server=%@", requestTraceId, serverTrace)
                  }
                  pendingDone = (messageId: decoded.message_id, chatId: resolvedChatId, traceId: decoded.trace_id)
                  didReceiveDone = true
                }
              }
            case "error":
              if let decoded = try? JSONDecoder().decode(ErrorPayload.self, from: data) {
                throw ChatSendError.server(code: decoded.code ?? "CH99", message: decoded.message ?? "unknown")
              }
              throw ChatSendError.server(code: "CH99", message: "unknown")
            default:
              break
            }
          }

          // NOTE: 不使用 `bytes.lines`：在部分系统版本上会出现“lines 序列为空但 bytes 实际有数据”的情况，
          // 导致 SSE 永远收不到 delta/done。这里改为按字节手动切行解析。
          var lineBytes: [UInt8] = []
          lineBytes.reserveCapacity(256)
          var shouldStop = false

          func flushLine() throws {
            let data = Data(lineBytes)
            lineBytes.removeAll(keepingCapacity: true)
            let raw = String(data: data, encoding: .utf8) ?? ""
            let line = raw.trimmingCharacters(in: CharacterSet(charactersIn: "\r"))

            if line.isEmpty {
              try dispatchEventIfNeeded()
              if didReceiveDone {
                shouldStop = true
              }
              return
            }
            if line.hasPrefix(":") { return }
            if line.hasPrefix("event:") {
              currentEvent = String(line.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
              return
            }
            if line.hasPrefix("data:") {
              var value = String(line.dropFirst(5))
              if value.hasPrefix(" ") { value.removeFirst() }
              dataLines.append(value)
              return
            }
          }

          for try await byte in bytes {
            try Task.checkCancellation()
            if byte == 0x0A { // \n
              try flushLine()
              if shouldStop {
                bytes.task.cancel()
                break
              }
            } else {
              lineBytes.append(byte)
            }
          }
          if !lineBytes.isEmpty {
            try flushLine()
          }

          try dispatchEventIfNeeded()
          if let done = pendingDone {
            if didYieldDelta != true,
               let messageId = done.messageId?.trimmingCharacters(in: .whitespacesAndNewlines),
               !messageId.isEmpty {
              let fetched = (try? await fetchAssistantMessageContent(messageId: messageId, config: config)) ?? nil
              if let fallback = fetched,
                 !fallback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                NSLog("ℹ️ ChatSendService | no delta received, fallback fetch message_id=%@", messageId)
                continuation.yield(.delta(fallback))
              }
            }
            continuation.yield(.done(messageId: done.messageId, chatId: done.chatId, traceId: done.traceId))
          }
          continuation.finish()
        } catch is CancellationError {
          continuation.finish(throwing: ChatSendError.cancelled)
        } catch {
          continuation.finish(throwing: error)
        }
      }

      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }
}

private extension ChatSendService {
  static func fetchAssistantMessageContent(messageId: String, config: SupabaseRuntime.Config) async throws -> String? {
    let baseURL = config.url
      .appendingPathComponent("rest")
      .appendingPathComponent("v1")
      .appendingPathComponent("messages")

    guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
      return nil
    }
    components.queryItems = [
      .init(name: "select", value: "id,role,content"),
      .init(name: "id", value: "eq.\(messageId)"),
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

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse else { return nil }
    guard (200..<300).contains(http.statusCode) else {
      let text = String(data: data, encoding: .utf8) ?? ""
      NSLog("⚠️ ChatSendService.fetchAssistantMessageContent | http=%d body=%@", http.statusCode, String(text.prefix(200)))
      return nil
    }

    struct Row: Decodable {
      let role: String?
      let content: String?
    }
    let rows = (try? JSONDecoder().decode([Row].self, from: data)) ?? []
    guard let row = rows.first else { return nil }
    let role = (row.role ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard role == "assistant" else { return nil }
    let content = (row.content ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    return content.isEmpty ? nil : content
  }
}

@MainActor
enum ChatCreateService {
  enum ChatCreateError: LocalizedError {
    case missingConfig
    case missingUserId
    case invalidResponse
    case http(status: Int, body: String)

    var errorDescription: String? {
      switch self {
      case .missingConfig:
        return "未配置 SUPABASE_URL + TOKEN/SUPABASE_JWT"
      case .missingUserId:
        return "未能解析用户身份（user_id）"
      case .invalidResponse:
        return "创建会话响应无效"
      case let .http(status, body):
        return "创建会话失败(\(status))：\(body)"
      }
    }
  }

  static func ensureChatExists(chatId: String, title: String?) async throws {
    let trimmedId = chatId.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedId.isEmpty else { throw ChatCreateError.invalidResponse }
    let config = try await SupabaseRuntime.loadConfigRefreshingIfNeeded()

    let userId =
      AuthSessionStore.load()?.userId ??
      userIdFromJWT(config.jwt)
    guard let userId, !userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw ChatCreateError.missingUserId
    }

    let baseURL = config.url
      .appendingPathComponent("rest")
      .appendingPathComponent("v1")
      .appendingPathComponent("chats")

    guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
      throw ChatCreateError.invalidResponse
    }
    components.queryItems = [
      .init(name: "on_conflict", value: "id")
    ]
    guard let url = components.url else { throw ChatCreateError.invalidResponse }

    var row: [String: Any] = [
      "id": trimmedId,
      "user_id": userId
    ]

    let cleanTitle = (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    if !cleanTitle.isEmpty {
      row["title"] = cleanTitle
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(SupabaseRuntime.makeTraceId(), forHTTPHeaderField: SupabaseRuntime.HeaderName.traceId)
    request.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
    if let anonKey = config.anonKey {
      request.setValue(anonKey, forHTTPHeaderField: "apikey")
    }
    request.setValue(SupabaseRuntime.authHeaderValue(for: config.jwt), forHTTPHeaderField: "Authorization")
    request.httpBody = try JSONSerialization.data(withJSONObject: [row], options: [])

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse else { throw ChatCreateError.invalidResponse }
    guard (200..<300).contains(http.statusCode) else {
      let text = String(data: data, encoding: .utf8) ?? ""
      throw ChatCreateError.http(status: http.statusCode, body: String(text.prefix(200)))
    }
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

@MainActor
enum ChatUpdateService {
  enum UpdateError: LocalizedError {
    case missingConfig
    case invalidChatId
    case invalidTitle
    case invalidResponse
    case http(status: Int, body: String)

    var errorDescription: String? {
      switch self {
      case .missingConfig:
        return "未配置 SUPABASE_URL + TOKEN/SUPABASE_JWT"
      case .invalidChatId:
        return "chat_id 无效"
      case .invalidTitle:
        return "title 无效"
      case .invalidResponse:
        return "更新会话信息响应无效"
      case let .http(status, body):
        return "更新会话信息失败(\(status))：\(body)"
      }
    }
  }

  static func updateChatTitle(chatId: String, title: String) async throws {
    let trimmedId = chatId.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedId.isEmpty else { throw UpdateError.invalidChatId }
    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedTitle.isEmpty else { throw UpdateError.invalidTitle }

    let config: SupabaseRuntime.Config
    do {
      config = try await SupabaseRuntime.loadConfigRefreshingIfNeeded()
    } catch let error as SupabaseRuntime.SessionError {
      if case .missingProjectConfig = error {
        throw UpdateError.missingConfig
      }
      throw error
    }

    let baseURL = config.url
      .appendingPathComponent("rest")
      .appendingPathComponent("v1")
      .appendingPathComponent("chats")

    guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
      throw UpdateError.invalidResponse
    }
    components.queryItems = [
      .init(name: "id", value: "eq.\(trimmedId)")
    ]
    guard let url = components.url else { throw UpdateError.invalidResponse }

    var request = URLRequest(url: url)
    request.httpMethod = "PATCH"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(SupabaseRuntime.makeTraceId(), forHTTPHeaderField: SupabaseRuntime.HeaderName.traceId)
    request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
    if let anonKey = config.anonKey {
      request.setValue(anonKey, forHTTPHeaderField: "apikey")
    }
    request.setValue(SupabaseRuntime.authHeaderValue(for: config.jwt), forHTTPHeaderField: "Authorization")
    request.httpBody = try JSONSerialization.data(withJSONObject: ["title": trimmedTitle], options: [])

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse else { throw UpdateError.invalidResponse }
    guard (200..<300).contains(http.statusCode) else {
      let text = String(data: data, encoding: .utf8) ?? ""
      throw UpdateError.http(status: http.statusCode, body: String(text.prefix(200)))
    }
  }
}
