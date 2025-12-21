import Foundation

enum AvatarUploadService {
  enum AvatarUploadError: LocalizedError {
    case missingConfig
    case invalidUserId
    case invalidResponse
    case http(status: Int, message: String)
    case cancelled

    var errorDescription: String? {
      switch self {
      case .missingConfig:
        return "未配置 Supabase 登录态"
      case .invalidUserId:
        return "用户 ID 无效"
      case .invalidResponse:
        return "头像上传响应无效"
      case let .http(status, message):
        return "头像上传失败(\(status))：\(message)"
      case .cancelled:
        return "请求已取消"
      }
    }
  }

  static func uploadAvatarJPEG(
    _ jpegData: Data,
    userId: String,
    traceId: String? = nil
  ) async throws -> String {
    let trimmedUserId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedUserId.isEmpty else { throw AvatarUploadError.invalidUserId }

    let config: SupabaseRuntime.Config
    do {
      config = try await SupabaseRuntime.loadConfigRefreshingIfNeeded()
    } catch {
      throw AvatarUploadError.missingConfig
    }

    let base = config.url.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    let fileName = "\(UUID().uuidString.lowercased()).jpg"
    let objectPath = "\(trimmedUserId)/\(fileName)"
    let encodedPath = encodeObjectPath(objectPath)

    guard let uploadURL = URL(string: "\(base)/storage/v1/object/avatars/\(encodedPath)") else {
      throw AvatarUploadError.invalidResponse
    }

    var request = URLRequest(url: uploadURL)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
    request.setValue("true", forHTTPHeaderField: "x-upsert")
    request.setValue(traceId ?? SupabaseRuntime.makeTraceId(), forHTTPHeaderField: SupabaseRuntime.HeaderName.traceId)
    if let anonKey = config.anonKey, !anonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      request.setValue(anonKey, forHTTPHeaderField: "apikey")
    }
    request.setValue(SupabaseRuntime.authHeaderValue(for: config.jwt), forHTTPHeaderField: "Authorization")
    request.httpBody = jpegData

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse else { throw AvatarUploadError.invalidResponse }
      guard (200..<300).contains(http.statusCode) else {
        throw AvatarUploadError.http(status: http.statusCode, message: parseErrorMessage(from: data))
      }

      // public bucket: 直接构造 public URL
      return "\(base)/storage/v1/object/public/avatars/\(encodedPath)"
    } catch is CancellationError {
      throw AvatarUploadError.cancelled
    }
  }

  private static func encodeObjectPath(_ path: String) -> String {
    path
      .split(separator: "/")
      .map { raw in
        let s = String(raw)
        return s.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? s
      }
      .joined(separator: "/")
  }

  private static func parseErrorMessage(from data: Data) -> String {
    if let obj = try? JSONSerialization.jsonObject(with: data, options: []),
       let dict = obj as? [String: Any] {
      let candidates = [
        dict["message"] as? String,
        dict["error"] as? String,
        dict["msg"] as? String,
      ]
      if let picked = candidates.compactMap({ $0?.trimmingCharacters(in: .whitespacesAndNewlines) })
        .first(where: { !$0.isEmpty }) {
        return picked
      }
    }

    let text = String(data: data, encoding: .utf8) ?? ""
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? "unknown" : String(trimmed.prefix(200))
  }
}

enum AvatarDiskCache {
  private static let directoryName = "staro-avatar-cache-v1"
  private static let remoteURLKeyPrefix = "staro.avatar.remoteUrl.v1."

  static func localURL(for userId: String) -> URL? {
    let trimmed = userId.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    guard let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
    let dir = base.appendingPathComponent(directoryName, isDirectory: true)
    do {
      try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    } catch {
      return nil
    }
    return dir.appendingPathComponent("\(trimmed).jpg")
  }

  static func hasLocalAvatar(userId: String) -> Bool {
    guard let url = localURL(for: userId) else { return false }
    return FileManager.default.fileExists(atPath: url.path)
  }

  static func save(_ data: Data, userId: String, remoteURL: String? = nil) {
    let trimmedUserId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedUserId.isEmpty else { return }
    guard let url = localURL(for: trimmedUserId) else { return }
    do {
      try data.write(to: url, options: .atomic)
    } catch {
      // ignore
    }
    if let remote = remoteURL?.trimmingCharacters(in: .whitespacesAndNewlines), !remote.isEmpty {
      UserDefaults.standard.set(remote, forKey: remoteURLKeyPrefix + trimmedUserId)
    }
  }

  static func clear(userId: String) {
    let trimmedUserId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedUserId.isEmpty else { return }
    UserDefaults.standard.removeObject(forKey: remoteURLKeyPrefix + trimmedUserId)
    guard let url = localURL(for: trimmedUserId) else { return }
    try? FileManager.default.removeItem(at: url)
  }

  static func sync(userId: String, remoteURL: String?) {
    let trimmedUserId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedUserId.isEmpty else { return }
    let trimmedRemote = (remoteURL ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedRemote.isEmpty {
      clear(userId: trimmedUserId)
      return
    }

    let key = remoteURLKeyPrefix + trimmedUserId
    let stored = (UserDefaults.standard.string(forKey: key) ?? "")
      .trimmingCharacters(in: .whitespacesAndNewlines)

    if stored != trimmedRemote {
      UserDefaults.standard.set(trimmedRemote, forKey: key)
      if let url = localURL(for: trimmedUserId) {
        try? FileManager.default.removeItem(at: url)
      }
    }

    guard !hasLocalAvatar(userId: trimmedUserId) else { return }
    prefetchDownload(userId: trimmedUserId, remoteURL: trimmedRemote)
  }

  private static func prefetchDownload(userId: String, remoteURL: String) {
    guard let url = URL(string: remoteURL) else { return }
    let key = remoteURLKeyPrefix + userId
    let expectedRemote = remoteURL

    Task.detached(priority: .background) {
      guard let data = try? Data(contentsOf: url) else { return }
      let stillExpected = (UserDefaults.standard.string(forKey: key) ?? "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
      guard stillExpected == expectedRemote else { return }
      save(data, userId: userId, remoteURL: expectedRemote)
    }
  }
}
