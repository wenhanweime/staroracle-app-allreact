import Foundation

public struct ChatMessage: Identifiable, Codable, Equatable, Sendable {
  public let id: String
  public var text: String
  public var isUser: Bool
  public var timestamp: Date
  public var isLoading: Bool
  public var isStreaming: Bool
  public var isResponse: Bool
  public var streamingText: String?
  public var model: String?
  public var awarenessInsight: AwarenessInsight?
  public var isAnalyzingAwareness: Bool

  public init(
    id: String,
    text: String,
    isUser: Bool,
    timestamp: Date = Date(),
    isLoading: Bool = false,
    isStreaming: Bool = false,
    isResponse: Bool = false,
    streamingText: String? = nil,
    model: String? = nil,
    awarenessInsight: AwarenessInsight? = nil,
    isAnalyzingAwareness: Bool = false
  ) {
    self.id = id
    self.text = text
    self.isUser = isUser
    self.timestamp = timestamp
    self.isLoading = isLoading
    self.isStreaming = isStreaming
    self.isResponse = isResponse
    self.streamingText = streamingText
    self.model = model
    self.awarenessInsight = awarenessInsight
    self.isAnalyzingAwareness = isAnalyzingAwareness
  }
}

public struct ConversationAwareness: Codable, Equatable, Sendable {
  public var overallLevel: OverallLevel
  public var conversationDepth: Double
  public var isAnalyzing: Bool
  public var insights: [AwarenessInsight]
  public var topicProgression: [String]

  public enum OverallLevel: String, Codable, Sendable {
    case none
    case low
    case medium
    case high
  }

  public init(
    overallLevel: OverallLevel = .none,
    conversationDepth: Double = 0,
    isAnalyzing: Bool = false,
    insights: [AwarenessInsight] = [],
    topicProgression: [String] = []
  ) {
    self.overallLevel = overallLevel
    self.conversationDepth = conversationDepth
    self.isAnalyzing = isAnalyzing
    self.insights = insights
    self.topicProgression = topicProgression
  }
}
