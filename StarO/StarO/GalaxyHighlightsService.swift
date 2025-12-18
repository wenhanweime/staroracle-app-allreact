import Foundation

@MainActor
enum GalaxyHighlightsService {
  struct Highlight: Decodable {
    let id: String?
    let galaxy_star_indices: [Int]?
    let created_at: String?
    let expires_at: String?
  }

  struct ListResponseBody: Decodable {
    let ok: Bool?
    let highlights: [Highlight]?
    let trace_id: String?
    let code: String?
    let message: String?
  }

  struct CreateResponseBody: Decodable {
    let ok: Bool?
    let highlight: Highlight?
    let trace_id: String?
    let code: String?
    let message: String?
  }

  private static let iso: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  private static let isoNoFraction = ISO8601DateFormatter()

  static func fetchActiveHighlights() async -> [(indices: [Int], expiresAt: Date)] {
    guard let config = SupabaseRuntime.loadConfig() else {
      NSLog("ℹ️ GalaxyHighlightsService | missing SUPABASE_URL + TOKEN/SUPABASE_JWT, skip highlight sync")
      return []
    }

    let url = config.url
      .appendingPathComponent("functions")
      .appendingPathComponent("v1")
      .appendingPathComponent("galaxy-highlights")

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
        NSLog("⚠️ GalaxyHighlightsService(list) | http=%d body=%@", http.statusCode, String(text.prefix(200)))
        return []
      }

      let decoded = try JSONDecoder().decode(ListResponseBody.self, from: data)
      let items = decoded.highlights ?? []
      var results: [(indices: [Int], expiresAt: Date)] = []
      results.reserveCapacity(items.count)

      for item in items {
        guard let indices = item.galaxy_star_indices, !indices.isEmpty else { continue }
        guard let expRaw = item.expires_at else { continue }
        let exp = iso.date(from: expRaw) ?? isoNoFraction.date(from: expRaw)
        guard let exp else { continue }
        results.append((indices: indices, expiresAt: exp))
      }
      return results
    } catch {
      NSLog("⚠️ GalaxyHighlightsService(list) | error=%@", error.localizedDescription)
      return []
    }
  }

  static func createHighlight(indices: [Int]) async -> Bool {
    guard !indices.isEmpty else { return false }
    guard let config = SupabaseRuntime.loadConfig() else { return false }

    let url = config.url
      .appendingPathComponent("functions")
      .appendingPathComponent("v1")
      .appendingPathComponent("galaxy-highlights")

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue(SupabaseRuntime.makeTraceId(), forHTTPHeaderField: SupabaseRuntime.HeaderName.traceId)
    if let anonKey = config.anonKey {
      request.setValue(anonKey, forHTTPHeaderField: "apikey")
    }
    request.setValue(SupabaseRuntime.authHeaderValue(for: config.jwt), forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: ["galaxy_star_indices": indices], options: [])
    } catch {
      return false
    }

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse else { return false }
      guard (200..<300).contains(http.statusCode) else {
        let text = String(data: data, encoding: .utf8) ?? ""
        NSLog("⚠️ GalaxyHighlightsService(create) | http=%d body=%@", http.statusCode, String(text.prefix(200)))
        return false
      }

      _ = try? JSONDecoder().decode(CreateResponseBody.self, from: data)
      return true
    } catch {
      NSLog("⚠️ GalaxyHighlightsService(create) | error=%@", error.localizedDescription)
      return false
    }
  }
}
