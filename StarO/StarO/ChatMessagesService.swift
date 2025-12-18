import Foundation
import StarOracleCore

@MainActor
enum ChatMessagesService {
  struct MessageRow: Decodable, Identifiable, Sendable {
    let id: String
    let role: String?
    let content: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
      case id
      case role
      case content
      case createdAt = "created_at"
    }
  }

  private static let iso: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  private static let isoNoFraction = ISO8601DateFormatter()

  static func fetchMessages(chatId: String, limit: Int = 200) async -> [StarOracleCore.ChatMessage] {
    let config: SupabaseRuntime.Config
    do {
      config = try await SupabaseRuntime.loadConfigRefreshingIfNeeded()
    } catch {
      NSLog("ℹ️ ChatMessagesService | missing session/config, skip message sync err=%@", error.localizedDescription)
      return []
    }

    let baseURL = config.url
      .appendingPathComponent("rest")
      .appendingPathComponent("v1")
      .appendingPathComponent("messages")

    guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return [] }
    components.queryItems = [
      .init(name: "select", value: "id,role,content,created_at"),
      .init(name: "chat_id", value: "eq.\(chatId)"),
      .init(name: "order", value: "created_at.asc"),
      .init(name: "limit", value: String(max(1, min(limit, 1000))))
    ]
    guard let url = components.url else { return [] }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
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
        NSLog("⚠️ ChatMessagesService | http=%d body=%@", http.statusCode, String(text.prefix(200)))
        return []
      }

      let rows = try JSONDecoder().decode([MessageRow].self, from: data)
      var result: [StarOracleCore.ChatMessage] = []
      result.reserveCapacity(rows.count)

      for row in rows {
        let role = (row.role ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let isUser: Bool
        switch role {
        case "user":
          isUser = true
        case "assistant":
          isUser = false
        default:
          continue
        }

        let text = (row.content ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { continue }

        let timestamp: Date = {
          guard let raw = row.createdAt?.trimmingCharacters(in: .whitespacesAndNewlines),
                !raw.isEmpty else { return Date() }
          if let parsed = iso.date(from: raw) { return parsed }
          if let parsed = isoNoFraction.date(from: raw) { return parsed }
          return Date()
        }()

        result.append(
          StarOracleCore.ChatMessage(
            id: row.id,
            text: text,
            isUser: isUser,
            timestamp: timestamp,
            isResponse: !isUser
          )
        )
      }

      return result
    } catch {
      NSLog("⚠️ ChatMessagesService | error=%@", error.localizedDescription)
      return []
    }
  }

  static func fetchLatestAssistantMessage(chatId: String) async -> StarOracleCore.ChatMessage? {
    let config: SupabaseRuntime.Config
    do {
      config = try await SupabaseRuntime.loadConfigRefreshingIfNeeded()
    } catch {
      NSLog("ℹ️ ChatMessagesService.fetchLatestAssistantMessage | missing session/config err=%@", error.localizedDescription)
      return nil
    }

    let baseURL = config.url
      .appendingPathComponent("rest")
      .appendingPathComponent("v1")
      .appendingPathComponent("messages")

    guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return nil }
    components.queryItems = [
      .init(name: "select", value: "id,role,content,created_at"),
      .init(name: "chat_id", value: "eq.\(chatId)"),
      .init(name: "role", value: "eq.assistant"),
      .init(name: "order", value: "created_at.desc"),
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

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse else { return nil }
      guard (200..<300).contains(http.statusCode) else {
        let text = String(data: data, encoding: .utf8) ?? ""
        NSLog("⚠️ ChatMessagesService.fetchLatestAssistantMessage | http=%d body=%@", http.statusCode, String(text.prefix(200)))
        return nil
      }

      let rows = try JSONDecoder().decode([MessageRow].self, from: data)
      guard let row = rows.first else { return nil }

      let text = (row.content ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      guard !text.isEmpty else { return nil }

      let timestamp: Date = {
        guard let raw = row.createdAt?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return Date() }
        if let parsed = iso.date(from: raw) { return parsed }
        if let parsed = isoNoFraction.date(from: raw) { return parsed }
        return Date()
      }()

      return StarOracleCore.ChatMessage(
        id: row.id,
        text: text,
        isUser: false,
        timestamp: timestamp,
        isResponse: true
      )
    } catch {
      NSLog("⚠️ ChatMessagesService.fetchLatestAssistantMessage | error=%@", error.localizedDescription)
      return nil
    }
  }
}
