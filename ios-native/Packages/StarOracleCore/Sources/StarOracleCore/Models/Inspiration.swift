import Foundation

public struct InspirationCard: Identifiable, Codable, Equatable, Sendable {
  public let id: String
  public var title: String
  public var question: String
  public var reflection: String
  public var tags: [String]
  public var emotionalTone: String
  public var category: String
  public var spawnedAt: Int?

  public init(
    id: String,
    title: String,
    question: String,
    reflection: String,
    tags: [String] = [],
    emotionalTone: String = "探寻中",
    category: String = "philosophy_and_existence",
    spawnedAt: Int? = nil
  ) {
    self.id = id
    self.title = title
    self.question = question
    self.reflection = reflection
    self.tags = tags
    self.emotionalTone = emotionalTone
    self.category = category
    self.spawnedAt = spawnedAt
  }
}

public struct GalaxyHighlight: Codable, Equatable, Sendable {
  public var colorHex: String

  public init(colorHex: String) {
    self.colorHex = colorHex
  }
}
