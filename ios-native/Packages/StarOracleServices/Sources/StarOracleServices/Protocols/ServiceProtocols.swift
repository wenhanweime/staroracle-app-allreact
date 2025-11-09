import Foundation
import StarOracleCore

public struct AIConfiguration: Codable, Equatable, Sendable {
  public var provider: String
  public var apiKey: String
  public var endpoint: URL
  public var model: String

  public init(provider: String, apiKey: String, endpoint: URL, model: String) {
    self.provider = provider
    self.apiKey = apiKey
    self.endpoint = endpoint
    self.model = model
  }
}

public struct AIRequestContext: Equatable, Sendable {
  public var history: [ChatMessage]
  public var metadata: [String: String]

  public init(history: [ChatMessage] = [], metadata: [String: String] = [:]) {
    self.history = history
    self.metadata = metadata
  }
}

public protocol AIStreamingTask {
  func cancel()
}

@MainActor
public protocol AIServiceProtocol: AnyObject {
  func streamResponse(
    for question: String,
    configuration: AIConfiguration,
    context: AIRequestContext
  ) -> AsyncThrowingStream<String, Error>

  func analyzeStarContent(
    question: String,
    answer: String,
    configuration: AIConfiguration
  ) async throws -> TagAnalysis

  func analyzeAwareness(
    question: String,
    answer: String,
    configuration: AIConfiguration
  ) async throws -> AwarenessInsight

  func generateConversationTitle(
    from messages: [ChatMessage],
    configuration: AIConfiguration
  ) async throws -> String

  func validate(configuration: AIConfiguration) async throws
}

public protocol SoundServiceProtocol: AnyObject {
  func preload()
  func play(_ sound: SoundEffect)
  func stop(_ sound: SoundEffect)
  func startAmbient()
  func stopAmbient()
}

public enum SoundEffect: String, CaseIterable, Sendable {
  case starClick
  case starLight
  case starReveal
  case ambient
  case uiClick
}

public protocol HapticServiceProtocol: AnyObject {
  func impact(_ style: HapticImpactStyle)
  func selectionChanged()
}

public enum HapticImpactStyle: Sendable {
  case light
  case medium
  case heavy
  case success
  case warning
  case error
}

@MainActor
public protocol InspirationServiceProtocol: AnyObject {
  func drawCard(for region: GalaxyRegion?) -> InspirationCard
}

@MainActor
public protocol TemplateServiceProtocol: AnyObject {
  func availableTemplates() async -> [ConstellationTemplate]
  func template(withId id: String) async -> ConstellationTemplate?
}

@MainActor
public protocol PreferenceServiceProtocol: AnyObject {
  func loadAIConfiguration() async -> AIConfiguration?
  func saveAIConfiguration(_ config: AIConfiguration) async throws
}

public protocol ResourceServiceProtocol: AnyObject {
  func resolveImageURL(named: String) -> URL?
  func loadJSONResource<T: Decodable>(_ name: String, as type: T.Type) throws -> T
}
