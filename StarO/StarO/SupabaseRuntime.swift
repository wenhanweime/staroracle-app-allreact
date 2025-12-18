import Foundation

enum SupabaseRuntime {
  enum HeaderName {
    static let traceId = "X-Trace-Id"
    static let idempotencyKey = "X-Idempotency-Key"
  }

  struct ProjectConfig: Sendable {
    let url: URL
    let anonKey: String?
  }

  struct Config: Sendable {
    let url: URL
    let jwt: String
    let anonKey: String?
  }

  static func loadConfig() -> Config? {
    guard let project = loadProjectConfig() else { return nil }
    let jwt =
      AuthSessionStore.load()?.accessToken ??
      loadJWTFromEnvironment() ??
      loadJWTFromBundlePlist(named: "SupabaseConfig")
    guard let jwt else { return nil }
    return Config(url: project.url, jwt: jwt, anonKey: project.anonKey)
  }

  static func loadProjectConfig() -> ProjectConfig? {
    if let config = loadProjectFromEnvironment() {
      return config
    }
    #if DEBUG
    if let config = loadProjectFromBundlePlist(named: "SupabaseConfig") {
      return config
    }
    #endif
    return nil
  }

  private static func loadProjectFromEnvironment() -> ProjectConfig? {
    let env = ProcessInfo.processInfo.environment
    guard
      let urlString = normalized(env["SUPABASE_URL"]) ?? normalized(env["VITE_SUPABASE_URL"]),
      let url = URL(string: urlString)
    else {
      return nil
    }
    let anonKey =
      normalized(env["SUPABASE_ANON_KEY"]) ??
      normalized(env["VITE_SUPABASE_ANON_KEY"])
    return ProjectConfig(url: url, anonKey: anonKey)
  }

  private static func loadJWTFromEnvironment() -> String? {
    let env = ProcessInfo.processInfo.environment
    return
      normalized(env["SUPABASE_JWT"]) ??
      normalized(env["SUPABASE_TOKEN"]) ??
      normalized(env["TOKEN"]) ??
      normalized(env["Personal_Access_Token"]) ??
      normalized(env["VITE_SUPABASE_JWT"])
  }

  #if DEBUG
  private static func loadProjectFromBundlePlist(named name: String) -> ProjectConfig? {
    guard let url = Bundle.main.url(forResource: name, withExtension: "plist"),
          let data = try? Data(contentsOf: url),
          let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
          let dict = plist as? [String: Any] else {
      return nil
    }

    let urlString =
      normalized(dict["SUPABASE_URL"] as? String) ??
      normalized(dict["VITE_SUPABASE_URL"] as? String)

    let anonKey =
      normalized(dict["SUPABASE_ANON_KEY"] as? String) ??
      normalized(dict["VITE_SUPABASE_ANON_KEY"] as? String)

    guard let urlString, let parsedURL = URL(string: urlString) else {
      return nil
    }
    return ProjectConfig(url: parsedURL, anonKey: anonKey)
  }
  #endif

  #if DEBUG
  private static func loadJWTFromBundlePlist(named name: String) -> String? {
    guard let url = Bundle.main.url(forResource: name, withExtension: "plist"),
          let data = try? Data(contentsOf: url),
          let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
          let dict = plist as? [String: Any] else {
      return nil
    }

    return
      normalized(dict["SUPABASE_JWT"] as? String) ??
      normalized(dict["SUPABASE_TOKEN"] as? String) ??
      normalized(dict["TOKEN"] as? String) ??
      normalized(dict["Personal_Access_Token"] as? String) ??
      normalized(dict["VITE_SUPABASE_JWT"] as? String)
  }
  #else
  private static func loadJWTFromBundlePlist(named _: String) -> String? { nil }
  #endif

  private static func normalized(_ value: String?) -> String? {
    guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
          !trimmed.isEmpty,
          !trimmed.hasPrefix("$(") else {
      return nil
    }
    return trimmed
  }

  static func authHeaderValue(for jwt: String) -> String {
    let trimmed = jwt.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.lowercased().hasPrefix("bearer ") ? trimmed : "Bearer \(trimmed)"
  }

  static func makeTraceId() -> String {
    UUID().uuidString.lowercased()
  }

  static func makeIdempotencyKey() -> String {
    UUID().uuidString.lowercased()
  }
}
