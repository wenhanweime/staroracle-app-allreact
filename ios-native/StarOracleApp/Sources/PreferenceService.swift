import Foundation
import StarOracleServices

@MainActor
final class LocalPreferenceService: PreferenceServiceProtocol {
  private let defaults: UserDefaults
  private let key = "aiConfiguration"

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  func loadAIConfiguration() async -> AIConfiguration? {
    guard let data = defaults.data(forKey: key) else { return nil }
    return try? JSONDecoder().decode(AIConfiguration.self, from: data)
  }

  func saveAIConfiguration(_ config: AIConfiguration) async throws {
    let data = try JSONEncoder().encode(config)
    defaults.set(data, forKey: key)
  }
}
