import Foundation
import StarOracleServices

enum AIConfigurationDefaults {
  static func load() -> AIConfiguration? {
    if let env = loadFromProcessEnvironment() {
      return env.config
    }
    if let plist = loadFromInfoPlist() {
      return plist.config
    }
    return nil
  }

  static func defaultSystemPrompt() -> String? {
    if let env = loadFromProcessEnvironment(),
       let prompt = env.prompt {
      return prompt
    }
    if let plist = loadFromInfoPlist() {
      return plist.prompt
    }
    return nil
  }

  private static func loadFromProcessEnvironment() -> (config: AIConfiguration, prompt: String?)? {
    let env = ProcessInfo.processInfo.environment
    guard let apiKey = normalized(env["VITE_OPENAI_API_KEY"]) ??
            normalized(env["VITE_DEFAULT_API_KEY"]),
          let endpointString = normalized(env["VITE_OPENAI_ENDPOINT"]) ??
            normalized(env["VITE_DEFAULT_ENDPOINT"]),
          let url = URL(string: endpointString) else {
      NSLog("ℹ️ [AIConfigurationDefaults] 环境变量中未找到完整的 API 配置")
      return nil
    }
    let provider = normalized(env["VITE_DEFAULT_PROVIDER"]) ?? "openai"
    let model = normalized(env["VITE_OPENAI_MODEL"]) ??
      normalized(env["VITE_DEFAULT_MODEL"]) ??
      "gpt-3.5-turbo"
    NSLog("ℹ️ [AIConfigurationDefaults] 使用环境变量配置 provider=%@ model=%@ endpoint=%@", provider, model, endpointString)
    return (AIConfiguration(provider: provider, apiKey: apiKey, endpoint: url, model: model), nil)
  }

  private static func loadFromInfoPlist() -> (config: AIConfiguration, prompt: String?)? {
    guard let url = Bundle.main.url(forResource: "AIConfigurationDefaults", withExtension: "plist"),
          let data = try? Data(contentsOf: url),
          let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
      NSLog("ℹ️ [AIConfigurationDefaults] 未找到 AIConfigurationDefaults.plist")
      return nil
    }
    guard let apiKeyRaw = dict["APIKey"] as? String,
          let apiKey = normalized(apiKeyRaw),
          let endpointRaw = dict["Endpoint"] as? String,
          let endpointString = normalized(endpointRaw),
          let url = URL(string: endpointString) else {
      NSLog("⚠️ [AIConfigurationDefaults] plist 中缺少 API Key 或 Endpoint")
      return nil
    }
    let provider = normalized(dict["Provider"] as? String) ?? "openai"
    let model = normalized(dict["Model"] as? String) ?? "gpt-3.5-turbo"
    let prompt = normalized(dict["SystemPrompt"] as? String)
    NSLog("ℹ️ [AIConfigurationDefaults] 使用 plist 默认配置 provider=%@ model=%@ endpoint=%@", provider, model, endpointString)
    return (AIConfiguration(provider: provider, apiKey: apiKey, endpoint: url, model: model), prompt)
  }

  private static func normalized(_ value: String?) -> String? {
    guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
          !trimmed.isEmpty,
          !trimmed.hasPrefix("$(") else {
      return nil
    }
    return trimmed
  }
}
