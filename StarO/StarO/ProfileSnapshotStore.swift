import Foundation

enum ProfileSnapshotStore {
  struct Snapshot: Codable, Sendable {
    let user: ProfileService.User
    let profile: ProfileService.Profile
    let stats: ProfileService.Stats?
    let cachedAt: Date
  }

  private static let cachePrefix = "staro.profileSnapshot.v1."

  static func load(userId: String?, email: String?) -> Snapshot? {
    guard let key = cacheKey(userId: userId, email: email),
          let data = UserDefaults.standard.data(forKey: key) else {
      return nil
    }
    do {
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      return try decoder.decode(Snapshot.self, from: data)
    } catch {
      return nil
    }
  }

  static func save(
    user: ProfileService.User,
    profile: ProfileService.Profile,
    stats: ProfileService.Stats?,
    userId: String?,
    email: String?
  ) {
    guard let key = cacheKey(userId: userId, email: email) else { return }
    let snapshot = Snapshot(user: user, profile: profile, stats: stats, cachedAt: Date())
    do {
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601
      let data = try encoder.encode(snapshot)
      UserDefaults.standard.set(data, forKey: key)
    } catch {
      // ignore
    }
  }

  static func clear(userId: String?, email: String?) {
    guard let key = cacheKey(userId: userId, email: email) else { return }
    UserDefaults.standard.removeObject(forKey: key)
  }

  private static func cacheKey(userId: String?, email: String?) -> String? {
    let trimmedId = (userId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmedId.isEmpty {
      return "\(cachePrefix)\(trimmedId)"
    }
    let trimmedEmail = (email ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if !trimmedEmail.isEmpty {
      return "\(cachePrefix)\(trimmedEmail)"
    }
    return nil
  }
}

