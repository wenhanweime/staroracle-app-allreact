import Foundation

@MainActor
enum GalaxySeedService {
  struct ResponseBody: Decodable {
    let ok: Bool?
    let user_id: String?
    let galaxy_seed: String?
    let trace_id: String?
    let code: String?
    let message: String?
  }

  static func fetchSeed() async -> UInt64? {
    guard let config = SupabaseRuntime.loadConfig() else {
      NSLog("ℹ️ GalaxySeedService | missing SUPABASE_URL + TOKEN/SUPABASE_JWT, fallback to default seed")
      return nil
    }

    let url = config.url
      .appendingPathComponent("functions")
      .appendingPathComponent("v1")
      .appendingPathComponent("get-galaxy-seed")

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
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
        NSLog("⚠️ GalaxySeedService | http=%d body=%@", http.statusCode, String(text.prefix(200)))
        return nil
      }
      let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
      guard let raw = decoded.galaxy_seed?.trimmingCharacters(in: .whitespacesAndNewlines),
            !raw.isEmpty else { return nil }

      // profiles.galaxy_seed is bigint/int64; treat as signed then preserve bit-pattern.
      if let i64 = Int64(raw) {
        return UInt64(bitPattern: i64)
      }
      if let u64 = UInt64(raw) {
        return u64
      }
      return nil
    } catch {
      NSLog("⚠️ GalaxySeedService | error=%@", error.localizedDescription)
      return nil
    }
  }
}
