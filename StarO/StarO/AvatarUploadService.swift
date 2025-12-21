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

