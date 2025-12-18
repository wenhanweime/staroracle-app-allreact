import Foundation

@MainActor
enum ChatListService {
  struct Chat: Decodable, Identifiable {
    let id: String
    let title: String?
    let created_at: String?
    let updated_at: String?
    let kind: String?
  }

  struct ResponseBody: Decodable {
    let ok: Bool?
    let chats: [Chat]?
    let trace_id: String?
    let code: String?
    let message: String?
  }

  static func fetchChats(kind: String? = "free", limit: Int = 30, before: String? = nil) async -> [Chat] {
    guard let config = SupabaseRuntime.loadConfig() else {
      NSLog("ℹ️ ChatListService | missing SUPABASE_URL + TOKEN/SUPABASE_JWT, skip chat list")
      return []
    }

    let baseURL = config.url
      .appendingPathComponent("functions")
      .appendingPathComponent("v1")
      .appendingPathComponent("chat-list")

    guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return [] }
    var items: [URLQueryItem] = [
      .init(name: "limit", value: String(max(1, min(limit, 100))))
    ]
    if let before, !before.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      items.append(.init(name: "before", value: before))
    }
    if let kind, !kind.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      items.append(.init(name: "kind", value: kind))
    }
    components.queryItems = items
    guard let url = components.url else { return [] }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
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
        NSLog("⚠️ ChatListService | http=%d body=%@", http.statusCode, String(text.prefix(200)))
        return []
      }
      let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
      return decoded.chats ?? []
    } catch {
      NSLog("⚠️ ChatListService | error=%@", error.localizedDescription)
      return []
    }
  }
}
