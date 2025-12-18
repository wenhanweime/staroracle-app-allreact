import Foundation
import StarOracleCore

enum StarPluckService {
  private struct InspirationContent: Decodable {
    let id: String?
    let content_type: String?
    let question: String?
    let answer: String?
    let tags: [String]?
    let created_at: String?
  }

  private struct InspirationResponseBody: Decodable {
    let type: String?
    let content: InspirationContent?
    let trace_id: String?
    let code: String?
    let message: String?
  }

  private static func parseISODate(_ raw: String?) -> Date? {
    guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
          !raw.isEmpty else { return nil }

    let withFraction = ISO8601DateFormatter()
    withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let parsed = withFraction.date(from: raw) { return parsed }

    let noFraction = ISO8601DateFormatter()
    noFraction.formatOptions = [.withInternetDateTime]
    return noFraction.date(from: raw)
  }

  static func pluckInspiration(tag: String? = nil) async -> InspirationCard? {
    guard let config = SupabaseRuntime.loadConfig() else {
      NSLog("ℹ️ StarPluckService | missing SUPABASE_URL + TOKEN/SUPABASE_JWT, fallback to local inspiration")
      return nil
    }

    let url = config.url
      .appendingPathComponent("functions")
      .appendingPathComponent("v1")
      .appendingPathComponent("star-pluck")

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(SupabaseRuntime.makeTraceId(), forHTTPHeaderField: SupabaseRuntime.HeaderName.traceId)
    if let anonKey = config.anonKey {
      request.setValue(anonKey, forHTTPHeaderField: "apikey")
    }
    request.setValue(SupabaseRuntime.authHeaderValue(for: config.jwt), forHTTPHeaderField: "Authorization")

    var body: [String: Any] = ["mode": "inspiration"]
    if let tag, !tag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      body["tag"] = tag
    }
    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
      return nil
    }

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse else { return nil }
      guard (200..<300).contains(http.statusCode) else {
        let text = String(data: data, encoding: .utf8) ?? ""
        NSLog("⚠️ StarPluckService(inspiration) | http=%d body=%@", http.statusCode, String(text.prefix(200)))
        return nil
      }

      let decoded = try JSONDecoder().decode(InspirationResponseBody.self, from: data)
      guard decoded.type == "inspiration", let content = decoded.content else { return nil }

      let question = (content.question ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      let answer = (content.answer ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      guard !question.isEmpty else { return nil }

      let createdAt = parseISODate(content.created_at)

      return InspirationCard(
        id: content.id ?? UUID().uuidString,
        title: "灵感卡",
        question: question,
        reflection: answer,
        tags: content.tags ?? [],
        emotionalTone: "探寻中",
        category: "philosophy_and_existence",
        spawnedAt: createdAt.map { Int($0.timeIntervalSince1970) }
      )
    } catch {
      NSLog("⚠️ StarPluckService(inspiration) | error=%@", error.localizedDescription)
      return nil
    }
  }
}
