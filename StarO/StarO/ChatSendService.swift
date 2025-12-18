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
          guard let config = SupabaseRuntime.loadConfig() else {
            throw ChatSendError.missingConfig
          }

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
                  continuation.yield(.done(messageId: decoded.message_id, chatId: resolvedChatId, traceId: decoded.trace_id))
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

          for try await rawLine in bytes.lines {
            try Task.checkCancellation()
            let line = rawLine.trimmingCharacters(in: .newlines)
            if line.isEmpty {
              try dispatchEventIfNeeded()
              continue
            }
            if line.hasPrefix(":") { continue }
            if line.hasPrefix("event:") {
              currentEvent = String(line.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
              continue
            }
            if line.hasPrefix("data:") {
              var value = String(line.dropFirst(5))
              if value.hasPrefix(" ") { value.removeFirst() }
              dataLines.append(value)
              continue
            }
          }

          try dispatchEventIfNeeded()
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
