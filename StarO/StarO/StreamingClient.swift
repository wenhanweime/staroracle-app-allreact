import Foundation

/// Lightweight SSE client for OpenAI-compatible /v1/chat/completions streaming.
/// Uses URLSession.bytes(for:) to iterate server-sent event lines.
final class StreamingClient: @unchecked Sendable {
  private var currentTask: Task<Void, Never>?

  private final class ChunkHandler: @unchecked Sendable {
    private let block: @Sendable (String) -> Void
    init(_ block: @escaping @Sendable (String) -> Void) { self.block = block }
    func call(_ chunk: String) { block(chunk) }
  }

  private final class CompletionHandler: @unchecked Sendable {
    private let block: @Sendable (_ fullText: String?, _ error: Error?) -> Void
    init(_ block: @escaping @Sendable (_ fullText: String?, _ error: Error?) -> Void) { self.block = block }
    func call(_ text: String?, _ error: Error?) { block(text, error) }
  }

  private struct StreamingJob: @unchecked Sendable {
    var request: URLRequest
    let chunkHandler: ChunkHandler
    let completionHandler: CompletionHandler

    func run() async {
      var full = ""
      do {
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
          completionHandler.call(nil, StreamingError.invalidResponse)
          return
        }
        guard (200..<300).contains(http.statusCode) else {
          let text = try? String(
            data: Data(try await bytes.reduce(into: [UInt8](), { $0.append($1) })),
            encoding: .utf8
          )
          completionHandler.call(nil, StreamingError.http(status: http.statusCode, body: text ?? ""))
          return
        }
        for try await line in bytes.lines {
          try Task.checkCancellation()
          let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
          guard trimmed.hasPrefix("data: ") else { continue }
          let payload = String(trimmed.dropFirst(6))
          if payload == "[DONE]" { break }
          guard let data = payload.data(using: .utf8) else { continue }
          if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
             let choices = json["choices"] as? [[String: Any]],
             let delta = choices.first?["delta"] as? [String: Any],
             let content = delta["content"] as? String,
             !content.isEmpty {
            full += content
            chunkHandler.call(content)
          }
        }
        completionHandler.call(full, nil)
      } catch is CancellationError {
        completionHandler.call(full.isEmpty ? nil : full, StreamingError.cancelled)
      } catch {
        completionHandler.call(full.isEmpty ? nil : full, error)
      }
    }
  }

  private enum StreamingError: LocalizedError {
    case invalidResponse
    case http(status: Int, body: String)
    case cancelled

    var errorDescription: String? {
      switch self {
      case .invalidResponse:
        return "SSE 响应无效"
      case let .http(status, body):
        return "SSE 请求失败 (\(status))：\(body)"
      case .cancelled:
        return "请求已取消"
      }
    }
  }

  struct Message: Codable {
    let role: String
    let content: String
  }

  struct RequestBody: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double?
    let maxTokens: Int?
    let stream: Bool

    enum CodingKeys: String, CodingKey {
      case model
      case messages
      case temperature
      case maxTokens = "max_tokens"
      case stream
    }
  }

  func startChatCompletionStream(
    endpoint: String,
    apiKey: String,
    model: String,
    messages: [Message],
    temperature: Double?,
    maxTokens: Int?,
    onChunk: @escaping @Sendable (String) -> Void,
    onComplete: @escaping @Sendable (_ fullText: String?, _ error: Error?) -> Void
  ) {
    cancel()

    let chunkHandler = ChunkHandler(onChunk)
    let completionHandler = CompletionHandler(onComplete)

    var request = URLRequest(url: URL(string: endpoint)!)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(StreamingClient.authHeaderValue(for: apiKey), forHTTPHeaderField: "Authorization")

    let body = RequestBody(
      model: model,
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
      stream: true
    )
    do {
      request.httpBody = try JSONEncoder().encode(body)
    } catch {
      completionHandler.call(nil, error)
      return
    }

    let job = StreamingJob(request: request, chunkHandler: chunkHandler, completionHandler: completionHandler)
    currentTask = Task {
      await job.run()
    }
  }

  func cancel() {
    currentTask?.cancel()
    currentTask = nil
  }

  private static func authHeaderValue(for apiKey: String) -> String {
    let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.lowercased().hasPrefix("bearer ") ? trimmed : "Bearer \(trimmed)"
  }
}
