import Foundation

public struct Star: Identifiable, Codable, Equatable, Sendable {
  public struct InsightLevel: Codable, Equatable, Sendable {
    public var value: Int
    public var description: String

    public init(value: Int, description: String) {
      self.value = value
      self.description = description
    }
  }

  public let id: String
  public var galaxyStarIndices: [Int]?
  public var x: Double
  public var y: Double
  public var size: Double
  public var brightness: Double
  public var question: String
  public var answer: String
  public var imageURL: URL?
  public var createdAt: Date
  public var isSpecial: Bool
  public var tags: [String]
  public var primaryCategory: String
  public var emotionalTone: [String]
  public var questionType: String?
  public var insightLevel: InsightLevel?
  public var initialLuminosity: Int?
  public var connectionPotential: Int?
  public var suggestedFollowUp: String?
  public var cardSummary: String?
  public var similarity: Double?
  public var isTemplate: Bool
  public var templateType: String?
  public var isStreaming: Bool
  public var isTransient: Bool

  public init(
    id: String,
    galaxyStarIndices: [Int]? = nil,
    x: Double,
    y: Double,
    size: Double,
    brightness: Double,
    question: String,
    answer: String,
    imageURL: URL?,
    createdAt: Date,
    isSpecial: Bool = false,
    tags: [String] = [],
    primaryCategory: String = "philosophy_and_existence",
    emotionalTone: [String] = [],
    questionType: String? = nil,
    insightLevel: InsightLevel? = nil,
    initialLuminosity: Int? = nil,
    connectionPotential: Int? = nil,
    suggestedFollowUp: String? = nil,
    cardSummary: String? = nil,
    similarity: Double? = nil,
    isTemplate: Bool = false,
    templateType: String? = nil,
    isStreaming: Bool = false,
    isTransient: Bool = false
  ) {
    self.id = id
    self.galaxyStarIndices = galaxyStarIndices
    self.x = x
    self.y = y
    self.size = size
    self.brightness = brightness
    self.question = question
    self.answer = answer
    self.imageURL = imageURL
    self.createdAt = createdAt
    self.isSpecial = isSpecial
    self.tags = tags
    self.primaryCategory = primaryCategory
    self.emotionalTone = emotionalTone
    self.questionType = questionType
    self.insightLevel = insightLevel
    self.initialLuminosity = initialLuminosity
    self.connectionPotential = connectionPotential
    self.suggestedFollowUp = suggestedFollowUp
    self.cardSummary = cardSummary
    self.similarity = similarity
    self.isTemplate = isTemplate
    self.templateType = templateType
    self.isStreaming = isStreaming
    self.isTransient = isTransient
  }
}
