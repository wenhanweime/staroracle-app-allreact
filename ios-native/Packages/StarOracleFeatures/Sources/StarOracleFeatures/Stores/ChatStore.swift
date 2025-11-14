import Foundation
import StarOracleCore
import StarOracleServices

@MainActor
public final class ChatStore: ObservableObject, ChatStoreProtocol {
  @Published public private(set) var messages: [ChatMessage] {
    willSet { logStateChange("messages -> \(newValue.count)") }
  }
  @Published public private(set) var isLoading: Bool {
    willSet { logStateChange("isLoading -> \(newValue)") }
  }
  @Published public private(set) var conversationTitle: String {
    willSet { logStateChange("conversationTitle -> \(newValue)") }
  }
  @Published public private(set) var conversationAwareness: ConversationAwareness {
    willSet { logStateChange("conversationAwareness updated") }
  }

  private let aiService: AIServiceProtocol
  private let configurationProvider: @Sendable () async -> AIConfiguration?
  private let stateLoggingEnabled = true

  public init(
    messages: [ChatMessage] = [],
    isLoading: Bool = false,
    conversationTitle: String = "",
    conversationAwareness: ConversationAwareness = ConversationAwareness(),
    aiService: AIServiceProtocol,
    configurationProvider: @escaping @Sendable () async -> AIConfiguration?
  ) {
    self.messages = messages
    self.isLoading = isLoading
    self.conversationTitle = conversationTitle
    self.conversationAwareness = conversationAwareness
    self.aiService = aiService
    self.configurationProvider = configurationProvider
  }

  public func addUserMessage(_ text: String) {
    let message = ChatMessage(
      id: "user-\(UUID().uuidString)",
      text: text,
      isUser: true
    )
    messages.append(message)
  }

  public func addAIMessage(_ text: String) {
    let message = ChatMessage(
      id: "ai-\(UUID().uuidString)",
      text: text,
      isUser: false,
      isResponse: true
    )
    messages.append(message)
  }

  public func beginStreamingAIMessage(initial: String?) -> String {
    let messageId = "ai-\(UUID().uuidString)"
    let message = ChatMessage(
      id: messageId,
      text: initial ?? "",
      isUser: false,
      isStreaming: true,
      streamingText: initial
    )
    messages.append(message)
    return messageId
  }

  public func updateStreamingMessage(id: String, text: String) {
    guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
    messages[index].text = text
    messages[index].streamingText = text
    messages[index].isStreaming = true
  }

  public func finalizeStreamingMessage(id: String) {
    guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
    messages[index].isStreaming = false
    messages[index].isResponse = true
  }

  public func setLoading(_ isLoading: Bool) {
    self.isLoading = isLoading
  }

  public func clearMessages() {
    messages = []
    conversationTitle = ""
    conversationAwareness = ConversationAwareness()
  }

  public func startAwarenessAnalysis(messageId: String) {
    guard let index = messages.firstIndex(where: { $0.id == messageId }) else { return }
    messages[index].isAnalyzingAwareness = true
  }

  public func completeAwarenessAnalysis(messageId: String, insight: AwarenessInsight) {
    guard let index = messages.firstIndex(where: { $0.id == messageId }) else { return }
    messages[index].isAnalyzingAwareness = false
    messages[index].awarenessInsight = insight
    refreshConversationAwareness()
  }

  public func refreshConversationAwareness() {
    let insights = messages
      .compactMap { $0.awarenessInsight }
      .filter { $0.hasInsight }
    var level: ConversationAwareness.OverallLevel = .none
    if insights.contains(where: { $0.insightLevel == .high }) {
      level = .high
    } else if insights.contains(where: { $0.insightLevel == .medium }) {
      level = .medium
    } else if insights.contains(where: { $0.insightLevel == .low }) {
      level = .low
    }
    let depth = Double(insights.count * 20).clamped(to: 0...100)
    let topics = Array(Set(insights.map { $0.insightType }))
    conversationAwareness = ConversationAwareness(
      overallLevel: level,
      conversationDepth: depth,
      isAnalyzing: conversationAwareness.isAnalyzing,
      insights: insights,
      topicProgression: topics
    )
  }

  public func setConversationAnalyzing(_ isAnalyzing: Bool) {
    conversationAwareness.isAnalyzing = isAnalyzing
  }

  public func setConversationTitle(_ title: String) {
    conversationTitle = title
  }

  public func loadMessages(_ messages: [ChatMessage], title: String? = nil) {
    self.messages = messages
    if let title, !title.isEmpty {
      conversationTitle = title
    }
  }

  public func generateConversationTitle() async throws {
    guard conversationTitle.isEmpty,
          messages.count >= 2,
          let config = await configurationProvider() else {
      return
    }
    let title = try await aiService.generateConversationTitle(
      from: messages,
      configuration: config
    )
    conversationTitle = title
  }
}

private extension ChatStore {
  func logStateChange(_ label: String) {
    guard stateLoggingEnabled else { return }
    NSLog("⚠️ ChatStore mutate \(label) | stack:\n\(Thread.callStackSymbols.joined(separator: "\n"))")
  }
}

private extension Double {
  func clamped(to range: ClosedRange<Double>) -> Double {
    max(range.lowerBound, min(range.upperBound, self))
  }
}
