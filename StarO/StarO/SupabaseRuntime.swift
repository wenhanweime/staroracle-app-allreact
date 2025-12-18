import Foundation

enum SupabaseRuntime {
  enum SessionError: LocalizedError {
    case missingProjectConfig
    case missingAnonKey
    case missingSession
    case invalidResponse
    case http(status: Int, message: String)
    case cancelled
    case keychainWriteFailed

    var errorDescription: String? {
      switch self {
      case .missingProjectConfig:
        return "未配置 SUPABASE_URL"
      case .missingAnonKey:
        return "未配置 SUPABASE_ANON_KEY"
      case .missingSession:
        return "未登录或登录态已丢失"
      case .invalidResponse:
        return "认证服务响应无效"
      case let .http(status, message):
        return "认证失败(\(status))：\(message)"
      case .cancelled:
        return "请求已取消"
      case .keychainWriteFailed:
        return "登录态写入系统 Keychain 失败"
      }
    }
  }

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

  static func loadConfigRefreshingIfNeeded() async throws -> Config {
    guard let project = loadProjectConfig() else { throw SessionError.missingProjectConfig }
    guard var session = AuthSessionStore.load() else { throw SessionError.missingSession }

    if session.expiresAt.timeIntervalSinceNow > 30 {
      return Config(url: project.url, jwt: session.accessToken, anonKey: project.anonKey)
    }

    guard let anonKey = project.anonKey, !anonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw SessionError.missingAnonKey
    }

    let refreshed = try await refreshSession(url: project.url, anonKey: anonKey, refreshToken: session.refreshToken)
    guard AuthSessionStore.save(refreshed) else {
      throw SessionError.keychainWriteFailed
    }
    session = refreshed
    return Config(url: project.url, jwt: session.accessToken, anonKey: project.anonKey)
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

private extension SupabaseRuntime {
  struct AuthResponse: Decodable {
    struct User: Decodable {
      let id: String?
      let email: String?
    }

    struct Session: Decodable {
      let access_token: String?
      let refresh_token: String?
      let expires_in: Int?
      let expires_at: Int?
      let user: User?
    }

    let access_token: String?
    let refresh_token: String?
    let expires_in: Int?
    let expires_at: Int?
    let user: User?
    let session: Session?

    func toAuthSession() -> AuthSession? {
      let accessToken = (access_token ?? session?.access_token)?.trimmingCharacters(in: .whitespacesAndNewlines)
      let refreshToken = (refresh_token ?? session?.refresh_token)?.trimmingCharacters(in: .whitespacesAndNewlines)
      guard let accessToken, !accessToken.isEmpty,
            let refreshToken, !refreshToken.isEmpty else {
        return nil
      }

      let expiresAt: Date = {
        if let seconds = expires_at ?? session?.expires_at {
          return Date(timeIntervalSince1970: TimeInterval(seconds))
        }
        if let expiresIn = expires_in ?? session?.expires_in {
          return Date().addingTimeInterval(TimeInterval(max(0, expiresIn)))
        }
        return Date().addingTimeInterval(3600)
      }()

      let userId = (user?.id ?? session?.user?.id)?.trimmingCharacters(in: .whitespacesAndNewlines)
      let email = (user?.email ?? session?.user?.email)?.trimmingCharacters(in: .whitespacesAndNewlines)

      return AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
        userId: userId,
        email: email
      )
    }
  }

  struct AuthErrorResponse: Decodable {
    let error: String?
    let error_description: String?
    let msg: String?
    let message: String?
  }

  static func refreshSession(url: URL, anonKey: String, refreshToken: String) async throws -> AuthSession {
    let tokenEndpoint = url
      .appendingPathComponent("auth")
      .appendingPathComponent("v1")
      .appendingPathComponent("token")

    guard var components = URLComponents(url: tokenEndpoint, resolvingAgainstBaseURL: false) else {
      throw SessionError.invalidResponse
    }
    components.queryItems = [.init(name: "grant_type", value: "refresh_token")]
    guard let endpoint = components.url else { throw SessionError.invalidResponse }

    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(makeTraceId(), forHTTPHeaderField: HeaderName.traceId)
    request.setValue(anonKey, forHTTPHeaderField: "apikey")
    request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
    request.httpBody = try JSONSerialization.data(withJSONObject: ["refresh_token": refreshToken], options: [])

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse else { throw SessionError.invalidResponse }
      guard (200..<300).contains(http.statusCode) else {
        throw SessionError.http(status: http.statusCode, message: parseAuthErrorMessage(from: data))
      }
      let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
      guard let session = decoded.toAuthSession() else { throw SessionError.invalidResponse }
      return session
    } catch is CancellationError {
      throw SessionError.cancelled
    }
  }

  static func parseAuthErrorMessage(from data: Data) -> String {
    if let decoded = try? JSONDecoder().decode(AuthErrorResponse.self, from: data) {
      let candidates = [
        decoded.message,
        decoded.error_description,
        decoded.error,
        decoded.msg
      ]
      if let picked = candidates.compactMap({ $0?.trimmingCharacters(in: .whitespacesAndNewlines) }).first(where: { !$0.isEmpty }) {
        return picked
      }
    }
    let text = String(data: data, encoding: .utf8) ?? ""
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? "unknown" : String(trimmed.prefix(200))
  }
}
