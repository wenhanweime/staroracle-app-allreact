import Foundation
import StarOracleCore

enum PersonalizedInspirationService {
  private struct ResponseItem: Decodable {
    let id: String?
    let kind: String?
    let title: String?
    let content: String?
    let tags: [String]?
  }

  private struct ResponseBody: Decodable {
    let items: [ResponseItem]?
    let trace_id: String?
    let code: String?
    let message: String?
    let error: String?
  }

  static func fetchCandidates(count: Int = 3) async -> [PersonalizedInspirationCandidate] {
    guard let config = SupabaseRuntime.loadConfig() else { return [] }
    let resolvedCount = max(1, min(5, count))

    let url = config.url
      .appendingPathComponent("functions")
      .appendingPathComponent("v1")
      .appendingPathComponent("inspiration-personalized")

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(SupabaseRuntime.makeTraceId(), forHTTPHeaderField: SupabaseRuntime.HeaderName.traceId)
    if let anonKey = config.anonKey {
      request.setValue(anonKey, forHTTPHeaderField: "apikey")
    }
    request.setValue(SupabaseRuntime.authHeaderValue(for: config.jwt), forHTTPHeaderField: "Authorization")

    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: ["count": resolvedCount], options: [])
    } catch {
      return []
    }

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse else { return [] }
      guard (200..<300).contains(http.statusCode) else {
        if StarOracleDebug.verboseLogsEnabled {
          let text = String(data: data, encoding: .utf8) ?? ""
          NSLog("⚠️ PersonalizedInspirationService | http=%d body=%@", http.statusCode, String(text.prefix(240)))
        }
        return []
      }

      let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
      guard let raw = decoded.items, !raw.isEmpty else { return [] }

      var result: [PersonalizedInspirationCandidate] = []
      result.reserveCapacity(raw.count)
      for item in raw {
        let kind = (item.kind ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let title = (item.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let content = (item.content ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !kind.isEmpty, !title.isEmpty, !content.isEmpty else { continue }
        let id = (item.id ?? UUID().uuidString).trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedId = id.isEmpty ? UUID().uuidString : id
        result.append(
          PersonalizedInspirationCandidate(
            id: resolvedId,
            kind: kind,
            title: title,
            content: content,
            tags: item.tags ?? []
          )
        )
      }
      return result
    } catch {
      if StarOracleDebug.verboseLogsEnabled {
        NSLog("⚠️ PersonalizedInspirationService | error=%@", error.localizedDescription)
      }
      return []
    }
  }
}

