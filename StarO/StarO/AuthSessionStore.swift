import Foundation
import Security

struct AuthSession: Codable, Sendable {
  let accessToken: String
  let refreshToken: String
  let expiresAt: Date
  let userId: String?
  let email: String?
}

enum AuthSessionStore {
  private static let account = "supabase_session"

  private static var service: String {
    let bundle = Bundle.main.bundleIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let bundle, !bundle.isEmpty {
      return "\(bundle).auth"
    }
    return "StarOracle.Auth"
  }

  static func load() -> AuthSession? {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecReturnData as String: true
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess else { return nil }
    guard let data = item as? Data else { return nil }

    do {
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      return try decoder.decode(AuthSession.self, from: data)
    } catch {
      return nil
    }
  }

  @discardableResult
  static func save(_ session: AuthSession) -> Bool {
    do {
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601
      let data = try encoder.encode(session)

      let baseQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: account
      ]
      SecItemDelete(baseQuery as CFDictionary)

      var addQuery = baseQuery
      addQuery[kSecValueData as String] = data
      addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
      let status = SecItemAdd(addQuery as CFDictionary, nil)
      if status != errSecSuccess {
        NSLog("❌ AuthSessionStore.save | status=%d service=%@", status, service)
      }
      return status == errSecSuccess
    } catch {
      return false
    }
  }

  static func clear() {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account
    ]
    SecItemDelete(query as CFDictionary)
  }
}
