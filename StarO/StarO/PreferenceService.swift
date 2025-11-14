import Foundation
import StarOracleServices

@MainActor
final class LocalPreferenceService: PreferenceServiceProtocol {
  private let defaults: UserDefaults
  private let key = "aiConfiguration"
  private var cachedDefault: AIConfiguration?

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  func loadAIConfiguration() async -> AIConfiguration? {
    if let data = defaults.data(forKey: key),
       let stored = try? JSONDecoder().decode(AIConfiguration.self, from: data) {
      NSLog("ℹ️ [PreferenceService] 使用用户保存的 AI 配置（provider=%@, endpoint=%@）", stored.provider, stored.endpoint.absoluteString)
      return stored
    }
    if let cachedDefault {
      NSLog("ℹ️ [PreferenceService] 使用缓存的默认 AI 配置（provider=%@）", cachedDefault.provider)
      return cachedDefault
    }
    let defaultConfig = AIConfigurationDefaults.load()
    if let defaultConfig {
      NSLog("ℹ️ [PreferenceService] 使用默认 AI 配置（provider=%@, endpoint=%@）", defaultConfig.provider, defaultConfig.endpoint.absoluteString)
    } else {
      NSLog("⚠️ [PreferenceService] 未找到任何 AI 配置")
    }
    cachedDefault = defaultConfig
    return defaultConfig
  }

  func saveAIConfiguration(_ config: AIConfiguration) async throws {
    let data = try JSONEncoder().encode(config)
    defaults.set(data, forKey: key)
    NSLog("✅ [PreferenceService] AI 配置已保存（provider=%@）", config.provider)
    cachedDefault = config
  }
}
