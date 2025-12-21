import Foundation
import StarOracleCore
import StarOracleFeatures
import StarOracleServices

@MainActor
final class AppEnvironment: ObservableObject {
  let authService: AuthService
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
  private var didSyncSupabaseStars = false
  private var switchSessionTask: Task<Void, Never>?

  private static let iso: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  private static let isoNoFraction = ISO8601DateFormatter()

  init(conversationStore: ConversationStore = .shared) {
    authService = AuthService()
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
      starStore: starStore,
      conversationStore: conversationStore,
      aiService: aiService,
      preferenceService: preferenceService
    )
  }

  func switchSession(to sessionId: String) {
    switchSessionTask?.cancel()
    guard let session = conversationStore.switchSession(to: sessionId) else { return }
    if SupabaseRuntime.loadConfig() != nil, session.hasSupabaseConversationStarted == true {
      conversationStore.beginReviewSession(forChatId: sessionId)
    }
    let messages = conversationStore.messages(forSession: sessionId)
    if session.hasCustomTitle != true {
      chatStore.setConversationTitle("")
    }
    chatStore.setLoading(false)
    chatStore.loadMessages(messages, title: session.hasCustomTitle == true ? session.displayTitle : nil)
    if session.hasCustomTitle != true {
      Task { @MainActor [weak self] in
        await self?.generateAndApplyTitleIfNeeded(chatId: sessionId)
      }
    }

    guard SupabaseRuntime.loadConfig() != nil else { return }
    guard messages.isEmpty else { return }

    switchSessionTask = Task { @MainActor [weak self] in
      guard let self else { return }
      let fetched = await ChatMessagesService.fetchMessages(chatId: sessionId, limit: 400)
      guard !Task.isCancelled else { return }
      guard self.conversationStore.currentSessionId == sessionId else { return }
      guard !fetched.isEmpty else { return }

      self.conversationStore.replaceSessionMessages(
        sessionId: sessionId,
        messages: fetched,
        updatedAt: fetched.last?.timestamp,
        markSupabaseConversationStarted: true
      )
      self.conversationStore.beginReviewSession(forChatId: sessionId)
      if session.hasCustomTitle != true {
        self.chatStore.setConversationTitle("")
      }
      self.chatStore.loadMessages(fetched, title: session.hasCustomTitle == true ? session.displayTitle : nil)
      if session.hasCustomTitle != true {
        await self.generateAndApplyTitleIfNeeded(chatId: sessionId)
      }
    }
  }

  func createSession(title: String?) {
    let session = conversationStore.createSession(title: title)
    if session.hasCustomTitle != true {
      chatStore.setConversationTitle("")
    }
    chatStore.loadMessages([], title: session.hasCustomTitle == true ? session.displayTitle : nil)
  }

  func renameSession(id: String, title: String) {
    conversationStore.renameSession(id: id, title: title)
  }

  func deleteSession(id: String) {
    conversationStore.deleteSession(id: id)
    let messages = conversationStore.messages(forSession: nil)
    let current = conversationStore.currentSession()
    if current?.hasCustomTitle != true {
      chatStore.setConversationTitle("")
    }
    chatStore.loadMessages(messages, title: current?.hasCustomTitle == true ? current?.displayTitle : nil)
  }

  func bootstrapConversationIfNeeded() {
    guard !didBootstrapConversation else { return }
    didBootstrapConversation = true
    conversationStore.bootstrapIfNeeded()
    let initialMessages = conversationStore.messages(forSession: nil)
    if !initialMessages.isEmpty {
      let current = conversationStore.currentSession()
      if current?.hasCustomTitle != true {
        chatStore.setConversationTitle("")
      }
      chatStore.loadMessages(initialMessages, title: current?.hasCustomTitle == true ? current?.displayTitle : nil)
      if current?.hasCustomTitle != true {
        Task { @MainActor [weak self] in
          await self?.generateAndApplyTitleIfNeeded(chatId: self?.conversationStore.currentSessionId ?? "")
        }
      }
    }
  }

  private func generateAndApplyTitleIfNeeded(chatId: String) async {
    let trimmedId = chatId.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedId.isEmpty else { return }
    guard conversationStore.currentSessionId == trimmedId else { return }
    guard let session = conversationStore.session(id: trimmedId) else { return }
    guard session.hasCustomTitle != true else { return }
    guard session.messages.count >= 2 else { return }

    do {
      try await chatStore.generateConversationTitle()
    } catch {
      NSLog("⚠️ AppEnvironment.generateConversationTitle | error=%@", error.localizedDescription)
      return
    }

    let generated = chatStore.conversationTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !generated.isEmpty else { return }
    guard conversationStore.currentSessionId == trimmedId else { return }
    guard let latest = conversationStore.session(id: trimmedId), latest.hasCustomTitle != true else { return }

    let currentTitle = latest.title.trimmingCharacters(in: .whitespacesAndNewlines)
    let isTemplateTitle = currentTitle.hasPrefix("关于") && (
      currentTitle.hasSuffix("的对话") ||
      currentTitle.hasSuffix("的聊天") ||
      currentTitle.hasSuffix("的讨论") ||
      currentTitle.hasSuffix("对话") ||
      currentTitle.hasSuffix("聊天") ||
      currentTitle.hasSuffix("讨论")
    )
    let isPlaceholder = currentTitle.isEmpty ||
      currentTitle == "新会话" ||
      currentTitle == "新对话" ||
      currentTitle == "未命名会话" ||
      isTemplateTitle
    guard isPlaceholder else { return }

    conversationStore.renameSession(id: trimmedId, title: generated)
    if SupabaseRuntime.loadConfig() != nil {
      try? await ChatUpdateService.updateChatTitle(chatId: trimmedId, title: generated)
    }
  }

  func syncSupabaseStarsIfNeeded(limit: Int = 200) async {
    guard SupabaseRuntime.loadConfig() != nil else { return }
    guard !didSyncSupabaseStars else { return }
    didSyncSupabaseStars = true
    let rows = await StarsService.fetchStars(limit: limit)
    let stars = rows.map { StarsService.toCoreStar(row: $0) }
    starStore.upsertConstellationStars(stars)
  }

  func openServerChat(_ chat: ChatListService.Chat) {
    Task { await openServerChatAsync(chat) }
  }

  private func openServerChatAsync(_ chat: ChatListService.Chat) async {
    guard SupabaseRuntime.loadConfig() != nil else { return }
    guard !chat.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

    await syncSupabaseStarsIfNeeded()

    let messages = await ChatMessagesService.fetchMessages(chatId: chat.id, limit: 400)
    let session = conversationStore.upsertSupabaseSession(
      id: chat.id,
      title: chat.title,
      messages: messages,
      createdAt: Self.parseISODate(chat.created_at),
      updatedAt: Self.parseISODate(chat.updated_at)
    )
    conversationStore.beginReviewSession(forChatId: chat.id)
    if session.hasCustomTitle != true {
      chatStore.setConversationTitle("")
    }
    chatStore.loadMessages(messages, title: session.hasCustomTitle == true ? session.displayTitle : nil)
    if session.hasCustomTitle != true {
      await generateAndApplyTitleIfNeeded(chatId: chat.id)
    }
  }

  private static func parseISODate(_ raw: String?) -> Date? {
    guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
          !raw.isEmpty else { return nil }
    if let parsed = iso.date(from: raw) { return parsed }
    return isoNoFraction.date(from: raw)
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
    guard Self.isLive(configuration: configuration) else {
      return try await fallback.generateConversationTitle(from: messages, configuration: configuration)
    }

    let transcript = messages
      .filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
      .prefix(12)
      .map { message in
        let trimmed = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let shortened = trimmed.count > 80 ? "\(trimmed.prefix(80))…" : trimmed
        return "\(message.isUser ? "用户" : "助手")：\(shortened)"
      }
      .joined(separator: "\n")

    let prompt = """
你是产品编辑，需要为聊天会话起一个“好理解、可扫读”的中文标题。

硬性规则：
- 只输出标题文本，不要解释
- 4-12 个汉字（宁短不长）
- 不要使用模板句：不要出现「关于」「对话」「聊天」「讨论」「提问」「咨询」等字样
- 不要包含引号、不要包含标点、不要换行
- 避免人名/邮箱/手机号/金额等敏感细节；尽量避免具体数字

对话内容：
\(transcript)
"""

    do {
      let request = try makeChatRequest(
        configuration: configuration,
        messages: [
          .init(role: "system", content: "你只输出标题文本，不要输出其他任何解释。"),
          .init(role: "user", content: prompt)
        ],
        stream: false,
        maxTokens: 24,
        temperature: 0.2
      )

      let (data, response) = try await urlSession.data(for: request)
      guard let http = response as? HTTPURLResponse else { throw AIServiceError.invalidResponse }
      guard (200..<300).contains(http.statusCode) else {
        let body = String(data: data, encoding: .utf8) ?? ""
        throw AIServiceError.http(status: http.statusCode, body: String(body.prefix(400)))
      }

      if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
         let choices = json["choices"] as? [[String: Any]],
         let message = choices.first?["message"] as? [String: Any],
         let content = message["content"] as? String {
       let cleaned = content
          .replacingOccurrences(of: "\n", with: " ")
          .trimmingCharacters(in: .whitespacesAndNewlines)
          .trimmingCharacters(in: CharacterSet(charactersIn: "\"“”‘’《》"))
          .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = Self.normalizeConversationTitle(cleaned)
        if !normalized.isEmpty {
          return normalized
        }
      }

      throw AIServiceError.invalidPayload
    } catch {
      NSLog("⚠️ LiveAIService.generateConversationTitle | fallback due to error=%@", error.localizedDescription)
      return try await fallback.generateConversationTitle(from: messages, configuration: configuration)
    }
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

private extension LiveAIService {
  static func normalizeConversationTitle(_ raw: String) -> String {
    var title = raw
      .replacingOccurrences(of: "\n", with: " ")
      .replacingOccurrences(of: "\r", with: " ")
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .trimmingCharacters(in: CharacterSet(charactersIn: "\"“”‘’《》"))
      .trimmingCharacters(in: .whitespacesAndNewlines)

    if let colon = title.lastIndex(of: "：") {
      title = String(title[title.index(after: colon)...])
    } else if let colon = title.lastIndex(of: ":") {
      title = String(title[title.index(after: colon)...])
    }
    title = title.trimmingCharacters(in: .whitespacesAndNewlines)

    if title.hasPrefix("关于") {
      title = String(title.dropFirst("关于".count))
    }

    let suffixes = ["的对话", "的聊天", "的讨论", "对话", "聊天", "讨论", "咨询", "提问"]
    for suffix in suffixes where title.hasSuffix(suffix) {
      title = String(title.dropLast(suffix.count))
    }

    let bannedScalars = CharacterSet(charactersIn: "\"“”‘’《》【】[]（）()，,。.！？?!:：;；—-·•")
    let scalars = title.unicodeScalars.filter { !bannedScalars.contains($0) }
    title = String(String.UnicodeScalarView(scalars))
      .trimmingCharacters(in: .whitespacesAndNewlines)

    if title.isEmpty { return "" }

    let bannedTokens = ["关于", "对话", "聊天", "讨论", "提问", "咨询"]
    for token in bannedTokens {
      title = title.replacingOccurrences(of: token, with: "")
    }
    title = title.trimmingCharacters(in: .whitespacesAndNewlines)
    if title.isEmpty { return "" }

    return String(title.prefix(12))
  }
}
