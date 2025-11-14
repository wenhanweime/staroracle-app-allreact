import Foundation
import StarOracleCore
import StarOracleFeatures
import StarOracleServices

@MainActor
final class AppEnvironment: ObservableObject {
  let aiService: AIServiceProtocol
  let preferenceService: PreferenceServiceProtocol
  let templateService: TemplateServiceProtocol
  let inspirationService: InspirationServiceProtocol
  let starStore: StarStore
  let chatStore: ChatStore
  let galaxyStore: GalaxyStore
  let galaxyGridStore: GalaxyGridStore
  let conversationStore: ConversationStore
  let chatBridge: NativeChatBridge
  private var didBootstrapConversation = false

  init(conversationStore: ConversationStore = .shared) {
    let aiService = LiveAIService()
    let inspirationService = MockInspirationService()
    let templateService = MockTemplateService()
    let preferenceService = LocalPreferenceService()
    let soundService = MockSoundService()
    let hapticService = MockHapticService()

    self.aiService = aiService
    self.preferenceService = preferenceService
    self.templateService = templateService
    self.inspirationService = inspirationService
    starStore = StarStore(
      aiService: aiService,
      inspirationService: inspirationService,
      templateService: templateService,
      preferenceService: preferenceService,
      soundService: soundService,
      hapticService: hapticService
    )

    chatStore = ChatStore(
      aiService: aiService,
      configurationProvider: { await preferenceService.loadAIConfiguration() }
    )

    galaxyStore = GalaxyStore()
    galaxyGridStore = GalaxyGridStore()

    self.conversationStore = conversationStore
    chatBridge = NativeChatBridge(
      chatStore: chatStore,
      conversationStore: conversationStore,
      aiService: aiService,
      preferenceService: preferenceService
    )
  }

  func switchSession(to sessionId: String) {
    guard let session = conversationStore.switchSession(to: sessionId) else { return }
    let messages = conversationStore.messages(forSession: sessionId)
    chatStore.loadMessages(messages, title: session.displayTitle)
  }

  func createSession(title: String?) {
    let session = conversationStore.createSession(title: title)
    chatStore.loadMessages([], title: session.displayTitle)
  }

  func renameSession(id: String, title: String) {
    conversationStore.renameSession(id: id, title: title)
  }

  func deleteSession(id: String) {
    conversationStore.deleteSession(id: id)
    let messages = conversationStore.messages(forSession: nil)
    chatStore.loadMessages(messages, title: conversationStore.currentSession()?.displayTitle)
  }

  func bootstrapConversationIfNeeded() {
    guard !didBootstrapConversation else { return }
    didBootstrapConversation = true
    conversationStore.bootstrapIfNeeded()
    let initialMessages = conversationStore.messages(forSession: nil)
    if !initialMessages.isEmpty {
      chatStore.loadMessages(initialMessages, title: conversationStore.currentSession()?.displayTitle)
    }
  }
}

// MARK: - Live AI Service (OpenAI-compatible)

@MainActor
final class LiveAIService: AIServiceProtocol {
  private let streamingClient = StreamingClient()
  private let fallback = MockAIService()
  private let urlSession: URLSession

  init(urlSession: URLSession = .shared) {
    self.urlSession = urlSession
  }

  func streamResponse(
    for question: String,
    configuration: AIConfiguration,
    context: AIRequestContext
  ) -> AsyncThrowingStream<String, Error> {
    guard Self.isLive(configuration: configuration) else {
      NSLog("ℹ️ LiveAIService.streamResponse | 使用 mock provider=%@", configuration.provider)
      return fallback.streamResponse(for: question, configuration: configuration, context: context)
    }

    NSLog("🎯 LiveAIService.streamResponse | provider=%@ endpoint=%@ model=%@", configuration.provider, configuration.endpoint.absoluteString, configuration.model)
    let messages = makeMessages(for: question, context: context)
    let endpoint = configuration.endpoint.absoluteString
    let apiKey = configuration.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    let client = streamingClient

    return AsyncThrowingStream { continuation in
      client.startChatCompletionStream(
        endpoint: endpoint,
        apiKey: apiKey,
        model: configuration.model,
        messages: messages,
        temperature: nil,
        maxTokens: nil,
        onChunk: { chunk in
          continuation.yield(chunk)
        },
        onComplete: { _, error in
          if let error {
            continuation.finish(throwing: error)
          } else {
            continuation.finish()
          }
        }
      )

      continuation.onTermination = { [weak streamingClient] _ in
        streamingClient?.cancel()
      }
    }
  }

  func analyzeStarContent(
    question: String,
    answer: String,
    configuration: AIConfiguration
  ) async throws -> TagAnalysis {
    try await fallback.analyzeStarContent(question: question, answer: answer, configuration: configuration)
  }

  func analyzeAwareness(
    question: String,
    answer: String,
    configuration: AIConfiguration
  ) async throws -> AwarenessInsight {
    try await fallback.analyzeAwareness(question: question, answer: answer, configuration: configuration)
  }

  func generateConversationTitle(
    from messages: [StarOracleCore.ChatMessage],
    configuration: AIConfiguration
  ) async throws -> String {
    try await fallback.generateConversationTitle(from: messages, configuration: configuration)
  }

  func validate(configuration: AIConfiguration) async throws {
    guard Self.isLive(configuration: configuration) else {
      try await fallback.validate(configuration: configuration)
      return
    }

    let request = try makeChatRequest(
      configuration: configuration,
      messages: [
        StreamingClient.Message(role: "user", content: "Hello, can you hear me?")
      ],
      stream: false,
      maxTokens: 12,
      temperature: 0.1
    )

    let (data, response) = try await urlSession.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw AIServiceError.invalidResponse
    }
    guard (200..<300).contains(http.statusCode) else {
      let body = String(data: data, encoding: .utf8) ?? ""
      throw AIServiceError.http(status: http.statusCode, body: body)
    }
    guard try LiveAIService.responseContainsChoices(data) else {
      throw AIServiceError.invalidPayload
    }
  }

  private func makeMessages(for question: String, context: AIRequestContext) -> [StreamingClient.Message] {
    var result: [StreamingClient.Message] = []
    if let prompt = context.metadata["systemPrompt"]?.trimmingCharacters(in: .whitespacesAndNewlines),
       !prompt.isEmpty {
      NSLog("🎯 LiveAIService.makeMessages | 注入 systemPrompt 前30字: %@...", String(prompt.prefix(30)))
      result.append(.init(role: "system", content: prompt))
    } else {
      NSLog("ℹ️ LiveAIService.makeMessages | 无系统提示")
    }
    for message in context.history {
      let trimmed = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { continue }
      result.append(.init(role: message.isUser ? "user" : "assistant", content: trimmed))
    }
    if result.filter({ $0.role != "system" }).isEmpty {
      result.append(.init(role: "user", content: question))
    }
    return result
  }

  private func makeChatRequest(
    configuration: AIConfiguration,
    messages: [StreamingClient.Message],
    stream: Bool,
    maxTokens: Int?,
    temperature: Double?
  ) throws -> URLRequest {
    var request = URLRequest(url: configuration.endpoint)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(Self.authHeaderValue(for: configuration.apiKey), forHTTPHeaderField: "Authorization")

    let body = StreamingClient.RequestBody(
      model: configuration.model,
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
      stream: stream
    )
    request.httpBody = try JSONEncoder().encode(body)
    return request
  }

  private static func responseContainsChoices(_ data: Data) throws -> Bool {
    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
       let choices = json["choices"] as? [Any],
       !choices.isEmpty {
      return true
    }
    return false
  }

  private static func isLive(configuration: AIConfiguration) -> Bool {
    guard configuration.provider.lowercased() != "mock" else { return false }
    return !configuration.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private static func authHeaderValue(for apiKey: String) -> String {
    let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.lowercased().hasPrefix("bearer ") ? trimmed : "Bearer \(trimmed)"
  }

  private enum AIServiceError: LocalizedError {
    case invalidResponse
    case invalidPayload
    case http(status: Int, body: String)

    var errorDescription: String? {
      switch self {
      case .invalidResponse:
        return "服务器响应不可用。"
      case .invalidPayload:
        return "API 响应格式不正确。"
      case let .http(status, body):
        return "请求失败 (\(status))：\(body)"
      }
    }
  }
}
