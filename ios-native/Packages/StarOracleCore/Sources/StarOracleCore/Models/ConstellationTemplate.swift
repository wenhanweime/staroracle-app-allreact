import Foundation

public struct ConstellationTemplate: Identifiable, Codable, Equatable, Sendable {
  public enum Element: String, Codable, CaseIterable, Sendable {
    case fire
    case earth
    case air
    case water
  }

  public let id: String
  public var name: String
  public var chineseName: String
  public var description: String
  public var element: Element
  public var stars: [TemplateStar]
  public var connections: [TemplateConnection]
  public var centerX: Double
  public var centerY: Double
  public var scale: Double

  public init(
    id: String,
    name: String,
    chineseName: String,
    description: String,
    element: Element,
    stars: [TemplateStar],
    connections: [TemplateConnection],
    centerX: Double,
    centerY: Double,
    scale: Double
  ) {
    self.id = id
    self.name = name
    self.chineseName = chineseName
    self.description = description
    self.element = element
    self.stars = stars
    self.connections = connections
    self.centerX = centerX
    self.centerY = centerY
    self.scale = scale
  }
}

public struct TemplateStar: Identifiable, Codable, Equatable, Sendable {
  public let id: String
  public var x: Double
  public var y: Double
  public var size: Double
  public var brightness: Double
  public var question: String
  public var answer: String
  public var tags: [String]
  public var primaryCategory: String?
  public var emotionalTone: [String]?
  public var questionType: String?
  public var insightLevel: Star.InsightLevel?
  public var initialLuminosity: Int?
  public var connectionPotential: Int?
  public var suggestedFollowUp: String?
  public var cardSummary: String?
  public var isMainStar: Bool

  public init(
    id: String,
    x: Double,
    y: Double,
    size: Double,
    brightness: Double,
    question: String,
    answer: String,
    tags: [String] = [],
    primaryCategory: String? = nil,
    emotionalTone: [String]? = nil,
    questionType: String? = nil,
    insightLevel: Star.InsightLevel? = nil,
    initialLuminosity: Int? = nil,
    connectionPotential: Int? = nil,
    suggestedFollowUp: String? = nil,
    cardSummary: String? = nil,
    isMainStar: Bool = false
  ) {
    self.id = id
    self.x = x
    self.y = y
    self.size = size
    self.brightness = brightness
    self.question = question
    self.answer = answer
    self.tags = tags
    self.primaryCategory = primaryCategory
    self.emotionalTone = emotionalTone
    self.questionType = questionType
    self.insightLevel = insightLevel
    self.initialLuminosity = initialLuminosity
    self.connectionPotential = connectionPotential
    self.suggestedFollowUp = suggestedFollowUp
    self.cardSummary = cardSummary
    self.isMainStar = isMainStar
  }
}

public struct TemplateConnection: Identifiable, Codable, Equatable, Sendable {
  public let id: String
  public var fromStarId: String
  public var toStarId: String
  public var strength: Double
  public var sharedTags: [String]

  public init(id: String, fromStarId: String, toStarId: String, strength: Double, sharedTags: [String] = []) {
    self.id = id
    self.fromStarId = fromStarId
    self.toStarId = toStarId
    self.strength = strength
    self.sharedTags = sharedTags
  }
}

public struct ConstellationTemplateInfo: Codable, Equatable, Sendable {
  public var name: String
  public var element: ConstellationTemplate.Element

  public init(name: String, element: ConstellationTemplate.Element) {
    self.name = name
    self.element = element
  }
}
