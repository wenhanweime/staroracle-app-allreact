import Foundation

// Lightweight SSE client for OpenAI-compatible /v1/chat/completions streaming
// Uses URLSession.bytes(for:) to iterate server-sent event lines.
public final class StreamingClient {
    private var currentTask: Task<Void, Never>? = nil
    
    public init() {}

    public struct Message: Codable { 
        public let role: String
        public let content: String
        
        public init(role: String, content: String) {
            self.role = role
            self.content = content
        }
    }

    struct RequestBody: Codable {
        let model: String
        let messages: [Message]
        let temperature: Double?
        let max_tokens: Int?
        let stream: Bool
    }

    public func startChatCompletionStream(
        endpoint: String,
        apiKey: String,
        model: String,
        messages: [Message],
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        onChunk: @escaping (String) -> Void,
        onComplete: @escaping (_ fullText: String?, _ error: Error?) -> Void
    ) {
        cancel()
        NSLog("🚀 [StreamingClient] start endpoint=%@ model=%@ messages=%d", endpoint, model, messages.count)

        currentTask = Task { [weak self] in
            var request = URLRequest(url: URL(string: endpoint)!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

            let body = RequestBody(
                model: model,
                messages: messages,
                temperature: temperature,
                max_tokens: maxTokens,
                stream: true
            )
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                NSLog("❌ [StreamingClient] encode error: %@", error.localizedDescription)
                onComplete(nil, error)
                return
            }

            var full = ""
            do {
                let (bytes, response) = try await URLSession.shared.bytes(for: request)
                guard let http = response as? HTTPURLResponse else {
                    onComplete(nil, NSError(domain: "StreamingClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                    return
                }
                guard (200..<300).contains(http.statusCode) else {
                    let text = try? String(bytes: Data(try await bytes.reduce(into: [UInt8](), { $0.append($1) })), encoding: .utf8)
                    let mapped = Self.mapStatus(http.statusCode)
                    NSLog("❌ [StreamingClient] HTTP %d %@", http.statusCode, text ?? "")
                    onComplete(nil, NSError(domain: "StreamingClient", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "\(mapped). \(text ?? "")"]))
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
                       let content = delta["content"] as? String, !content.isEmpty {
                        full += content
                        NSLog("✉️ [StreamingClient] chunk len=%d", content.count)
                        onChunk(content)
                    }
                }
                NSLog("✅ [StreamingClient] finish, totalLen=%d", full.count)
                onComplete(full, nil)
            } catch is CancellationError {
                onComplete(full.isEmpty ? nil : full, NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil))
            } catch {
                NSLog("❌ [StreamingClient] error: %@", error.localizedDescription)
                onComplete(full.isEmpty ? nil : full, error)
            }
            // clear task when finished
            if let strong = self, strong.currentTask?.isCancelled == false { strong.currentTask = nil }
        }
    }

    public func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }

    private static func mapStatus(_ code: Int) -> String {
        switch code {
        case 401: return "认证失败（401），请检查 API Key"
        case 403: return "无权限（403），请检查账号或额度"
        case 408: return "请求超时（408）"
        case 429: return "请求过多（429），稍后重试"
        case 500...599: return "服务端异常（\(code)）"
        default: return "请求失败（\(code)）"
        }
    }
}
