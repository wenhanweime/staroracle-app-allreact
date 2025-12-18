import Foundation

enum EnergyService {
  struct Energy: Decodable, Sendable {
    let day: String?
    let remaining: Int?
  }

  private struct SuccessResponse: Decodable {
    let ok: Bool?
    let energy: Energy?
    let trace_id: String?
    let code: String?
    let message: String?
  }

  private struct ErrorResponse: Decodable {
    let ok: Bool?
    let code: String?
    let message: String?
    let trace_id: String?
    let energy: Energy?
  }

  enum EnergyError: LocalizedError {
    case missingConfig
    case invalidResponse
    case http(status: Int, code: String, message: String)
    case cancelled

    var errorDescription: String? {
      switch self {
      case .missingConfig:
        return "未配置 SUPABASE_URL + TOKEN/SUPABASE_JWT"
      case .invalidResponse:
        return "get-energy 响应无效"
      case let .http(status, code, message):
        return "get-energy 请求失败(\(status))：\(code) \(message)"
      case .cancelled:
        return "请求已取消"
      }
    }
  }

  static func getEnergy(traceId: String? = nil) async throws -> Energy {
    guard let config = SupabaseRuntime.loadConfig() else {
      throw EnergyError.missingConfig
    }

    let url = config.url
      .appendingPathComponent("functions")
      .appendingPathComponent("v1")
      .appendingPathComponent("get-energy")

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue(traceId ?? SupabaseRuntime.makeTraceId(), forHTTPHeaderField: SupabaseRuntime.HeaderName.traceId)
    if let anonKey = config.anonKey {
      request.setValue(anonKey, forHTTPHeaderField: "apikey")
    }
    request.setValue(SupabaseRuntime.authHeaderValue(for: config.jwt), forHTTPHeaderField: "Authorization")

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse else {
        throw EnergyError.invalidResponse
      }

      if (200..<300).contains(http.statusCode) {
        let decoded = try JSONDecoder().decode(SuccessResponse.self, from: data)
        guard let energy = decoded.energy else {
          throw EnergyError.invalidResponse
        }
        return energy
      }

      if let decoded = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
        throw EnergyError.http(
          status: http.statusCode,
          code: decoded.code ?? "EN99",
          message: decoded.message ?? "unknown"
        )
      }

      let text = String(data: data, encoding: .utf8) ?? ""
      throw EnergyError.http(status: http.statusCode, code: "EN99", message: String(text.prefix(200)))
    } catch is CancellationError {
      throw EnergyError.cancelled
    }
  }
}

