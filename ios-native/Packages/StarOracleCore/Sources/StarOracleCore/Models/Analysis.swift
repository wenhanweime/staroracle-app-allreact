import Foundation

public struct TagAnalysis: Codable, Equatable, Sendable {
  public var tags: [String]
  public var primaryCategory: String
  public var emotionalTone: [String]
  public var questionType: String
  public var insightLevel: Star.InsightLevel
  public var initialLuminosity: Int
  public var connectionPotential: Int
  public var suggestedFollowUp: String
  public var cardSummary: String

  public init(
    tags: [String] = [],
    primaryCategory: String = "philosophy_and_existence",
    emotionalTone: [String] = [],
    questionType: String = "探索型",
    insightLevel: Star.InsightLevel = .init(value: 1, description: "星尘"),
    initialLuminosity: Int = 60,
    connectionPotential: Int = 3,
    suggestedFollowUp: String = "",
    cardSummary: String = ""
  ) {
    self.tags = tags
    self.primaryCategory = primaryCategory
    self.emotionalTone = emotionalTone
    self.questionType = questionType
    self.insightLevel = insightLevel
    self.initialLuminosity = initialLuminosity
    self.connectionPotential = connectionPotential
    self.suggestedFollowUp = suggestedFollowUp
    self.cardSummary = cardSummary
  }
}

public struct AwarenessInsight: Codable, Equatable, Sendable {
  public var hasInsight: Bool
  public var insightLevel: InsightLevel
  public var insightType: String
  public var keyInsights: [String]
  public var emotionalPattern: String
  public var suggestedReflection: String
  public var followUpQuestions: [String]

  public enum InsightLevel: String, Codable, Sendable {
    case low
    case medium
    case high
  }

  public init(
    hasInsight: Bool = false,
    insightLevel: InsightLevel = .low,
    insightType: String = "一般对话",
    keyInsights: [String] = [],
    emotionalPattern: String = "日常交流模式",
    suggestedReflection: String = "继续探索这个话题可能会带来更深的洞察。",
    followUpQuestions: [String] = ["你对这个话题还有什么想法？"]
  ) {
    self.hasInsight = hasInsight
    self.insightLevel = insightLevel
    self.insightType = insightType
    self.keyInsights = keyInsights
    self.emotionalPattern = emotionalPattern
    self.suggestedReflection = suggestedReflection
    self.followUpQuestions = followUpQuestions
  }
}
