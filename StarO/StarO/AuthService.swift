import Combine
import Foundation

@MainActor
final class AuthService: ObservableObject {
  enum AuthError: LocalizedError {
    case missingProjectConfig
    case missingAnonKey
    case invalidResponse
    case http(status: Int, message: String)
    case signupNeedsConfirmation
    case cancelled

    var errorDescription: String? {
      switch self {
      case .missingProjectConfig:
        return "未配置 SUPABASE_URL"
      case .missingAnonKey:
        return "未配置 SUPABASE_ANON_KEY"
      case .invalidResponse:
        return "认证服务响应无效"
      case let .http(status, message):
        return "认证失败(\(status))：\(message)"
      case .signupNeedsConfirmation:
        return "注册成功，请前往邮箱完成验证后再登录。"
      case .cancelled:
        return "请求已取消"
      }
    }
  }

  @Published private(set) var isAuthenticated: Bool = false
  @Published private(set) var userEmail: String?
  @Published private(set) var isLoading: Bool = false
  @Published var errorMessage: String?

  @Published private(set) var energyDay: String?
  @Published private(set) var energyRemaining: Int?

  private var didRestore = false

  func restoreSessionIfNeeded() async {
    guard !didRestore else { return }
    didRestore = true
    await restoreSession()
  }

  func restoreSession() async {
    guard let session = AuthSessionStore.load() else {
      isAuthenticated = false
      userEmail = nil
      return
    }

    if session.expiresAt.timeIntervalSinceNow > 30 {
      applySession(session)
      await refreshEnergy()
      return
    }

    do {
      let refreshed = try await refreshSession(refreshToken: session.refreshToken)
      applySession(refreshed)
      await refreshEnergy()
    } catch {
      AuthSessionStore.clear()
      isAuthenticated = false
      userEmail = nil
      energyDay = nil
      energyRemaining = nil
      errorMessage = presentableErrorMessage(for: error)
    }
  }

  func signIn(email: String, password: String) async {
    let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
      errorMessage = "请输入邮箱和密码。"
      return
    }

    isLoading = true
    defer { isLoading = false }
    errorMessage = nil

    do {
      let session = try await requestSession(grantType: "password", body: [
        "email": trimmedEmail,
        "password": trimmedPassword
      ])
      applySession(session)
      await refreshEnergy()
    } catch {
      errorMessage = presentableErrorMessage(for: error)
    }
  }

  func signUp(email: String, password: String) async {
    let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
      errorMessage = "请输入邮箱和密码。"
      return
    }

    isLoading = true
    defer { isLoading = false }
    errorMessage = nil

    do {
      let project = try projectConfig()
      let url = project.url
        .appendingPathComponent("auth")
        .appendingPathComponent("v1")
        .appendingPathComponent("signup")

      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Accept")
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.setValue(SupabaseRuntime.makeTraceId(), forHTTPHeaderField: SupabaseRuntime.HeaderName.traceId)
      request.setValue(project.anonKey, forHTTPHeaderField: "apikey")
      request.setValue("Bearer \(project.anonKey)", forHTTPHeaderField: "Authorization")
      request.httpBody = try JSONSerialization.data(withJSONObject: [
        "email": trimmedEmail,
        "password": trimmedPassword
      ], options: [])

      let (data, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
      guard (200..<300).contains(http.statusCode) else {
        throw AuthError.http(status: http.statusCode, message: parseErrorMessage(from: data))
      }

      let decoded = try JSONDecoder().decode(SupabaseAuthResponse.self, from: data)
      if let session = decoded.toAuthSession(defaultEmail: trimmedEmail) {
        applySession(session)
        await refreshEnergy()
        return
      }

      // No session returned → email confirmation likely enabled.
      throw AuthError.signupNeedsConfirmation
    } catch {
      errorMessage = presentableErrorMessage(for: error)
    }
  }

  func signOut() async {
    isLoading = true
    defer { isLoading = false }
    errorMessage = nil

    if let config = SupabaseRuntime.loadConfig() {
      let url = config.url
        .appendingPathComponent("auth")
        .appendingPathComponent("v1")
        .appendingPathComponent("logout")

      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.setValue(SupabaseRuntime.makeTraceId(), forHTTPHeaderField: SupabaseRuntime.HeaderName.traceId)
      if let anonKey = config.anonKey {
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
      }
      request.setValue(SupabaseRuntime.authHeaderValue(for: config.jwt), forHTTPHeaderField: "Authorization")

      _ = try? await URLSession.shared.data(for: request)
    }

    AuthSessionStore.clear()
    isAuthenticated = false
    userEmail = nil
    energyDay = nil
    energyRemaining = nil
  }

  private func applySession(_ session: AuthSession) {
    let saved = AuthSessionStore.save(session)
    guard saved else {
      isAuthenticated = false
      userEmail = nil
      errorMessage = "登录态写入系统 Keychain 失败，请重启 App 或重装后重试。"
      return
    }
    isAuthenticated = true
    userEmail = session.email
  }

  private func refreshEnergy() async {
    do {
      let energy = try await EnergyService.getEnergy()
      energyDay = energy.day
      energyRemaining = energy.remaining
    } catch {
      NSLog("⚠️ AuthService.get-energy | error=%@", error.localizedDescription)
    }
  }

  private func presentableErrorMessage(for error: Error) -> String {
    if let authError = error as? AuthError {
      if case let .http(status, message) = authError {
        let normalized = message.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if status == 400 || status == 401 {
          if normalized.contains("invalid login credentials") ||
            normalized.contains("invalid_grant") ||
            normalized.contains("invalid_credentials") {
            return "邮箱或密码错误。"
          }
          if normalized.contains("email not confirmed") || normalized.contains("email_not_confirmed") {
            return "邮箱尚未验证，请先完成邮箱验证后再登录。"
          }
        }
      }
      return authError.localizedDescription
    }

    if let urlError = error as? URLError {
      switch urlError.code {
      case .notConnectedToInternet:
        return "网络不可用，请检查网络连接。"
      case .networkConnectionLost:
        return "网络连接中断，请重试。"
      case .timedOut:
        return "网络超时，请稍后重试。"
      case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
        return "无法连接服务器，请检查 SUPABASE_URL 配置。"
      case .secureConnectionFailed, .serverCertificateUntrusted, .serverCertificateHasBadDate, .serverCertificateHasUnknownRoot, .serverCertificateNotYetValid:
        return "安全连接失败，请检查系统时间或网络环境。"
      default:
        break
      }
    }

    return error.localizedDescription
  }

  private func refreshSession(refreshToken: String) async throws -> AuthSession {
    try await requestSession(grantType: "refresh_token", body: ["refresh_token": refreshToken])
  }

  private func requestSession(grantType: String, body: [String: Any]) async throws -> AuthSession {
    let project = try projectConfig()

    let tokenEndpoint = project.url
      .appendingPathComponent("auth")
      .appendingPathComponent("v1")
      .appendingPathComponent("token")

    guard var components = URLComponents(url: tokenEndpoint, resolvingAgainstBaseURL: false) else {
      throw AuthError.invalidResponse
    }
    components.queryItems = [.init(name: "grant_type", value: grantType)]
    guard let url = components.url else { throw AuthError.invalidResponse }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(SupabaseRuntime.makeTraceId(), forHTTPHeaderField: SupabaseRuntime.HeaderName.traceId)
    request.setValue(project.anonKey, forHTTPHeaderField: "apikey")
    request.setValue("Bearer \(project.anonKey)", forHTTPHeaderField: "Authorization")
    request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
      guard (200..<300).contains(http.statusCode) else {
        throw AuthError.http(status: http.statusCode, message: parseErrorMessage(from: data))
      }

      let decoded = try JSONDecoder().decode(SupabaseAuthResponse.self, from: data)
      if let session = decoded.toAuthSession(defaultEmail: nil) {
        return session
      }
      throw AuthError.invalidResponse
    } catch is CancellationError {
      throw AuthError.cancelled
    }
  }

  private func projectConfig() throws -> (url: URL, anonKey: String) {
    guard let config = SupabaseRuntime.loadProjectConfig() else {
      throw AuthError.missingProjectConfig
    }
    guard let anonKey = config.anonKey, !anonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw AuthError.missingAnonKey
    }
    return (url: config.url, anonKey: anonKey)
  }

  private func parseErrorMessage(from data: Data) -> String {
    if let decoded = try? JSONDecoder().decode(SupabaseAuthErrorResponse.self, from: data) {
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

private struct SupabaseAuthResponse: Decodable {
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

  func toAuthSession(defaultEmail: String?) -> AuthSession? {
    let accessToken = (access_token ?? session?.access_token)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let refreshToken = (refresh_token ?? session?.refresh_token)?.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let accessToken, !accessToken.isEmpty,
          let refreshToken, !refreshToken.isEmpty else {
      return nil
    }

    let expiresAt: Date = {
      if let expiresAt = expires_at ?? session?.expires_at {
        return Date(timeIntervalSince1970: TimeInterval(expiresAt))
      }
      if let expiresIn = expires_in ?? session?.expires_in {
        return Date().addingTimeInterval(TimeInterval(max(0, expiresIn)))
      }
      return Date().addingTimeInterval(3600)
    }()

    let userId = (user?.id ?? session?.user?.id)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let email = (user?.email ?? session?.user?.email ?? defaultEmail)?.trimmingCharacters(in: .whitespacesAndNewlines)

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      userId: userId,
      email: email
    )
  }
}

private struct SupabaseAuthErrorResponse: Decodable {
  let error: String?
  let error_description: String?
  let msg: String?
  let message: String?
}
